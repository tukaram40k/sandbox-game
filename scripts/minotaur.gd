extends CharacterBody2D

# Movement properties
var speed = 100
var patrol_speed = 50
var follow_speed = 75
var chase_speed = 120

# State management
enum State {IDLE, PATROL, ALERT, FOLLOW, RETREAT, AGGRESSIVE}
var current_state = State.IDLE
var previous_state = State.IDLE
var player_state

# Timer variables
var state_timer = 0
var decision_timer = 0
var idle_time = 3.0  # How long to stay idle before patrolling
var patrol_time = 5.0  # How long to patrol before idling again
var alert_time = 2.0  # How long to be alert before deciding to follow
var curious_inspection_time = 2.0  # How long to inspect interesting things

# Target and awareness variables
var player = null
var detect_radius = 200  # Distance at which minotaur notices player
var follow_radius = 300  # Max distance for following
var personal_space = 50  # Minimum distance to maintain from player
var aggression_threshold = 20.0  # Time following before becoming aggressive
var time_following = 0.0
var aggression_chance = 0.2  # Chance to become aggressive when threshold is met
var follow_chance = 0.7  # Chance to follow after alert state
var target_position = Vector2.ZERO

# Patrol variables
var patrol_points = []
var current_patrol_point = 0
var patrol_point_reach_distance = 20
var generate_patrol_range = 150  # Range for generating random patrol points
var home_position = Vector2.ZERO

# Inspection variables
var inspection_chance = 0.01  # Chance per second to stop and inspect something
var is_inspecting = false
var inspection_timer = 0.0
var inspection_position = Vector2.ZERO

# System variables
var rng = RandomNumberGenerator.new()
var debug_mode = true  # Set to true to print debug information

func _ready():
	# Initialize random number generator
	rng.randomize()
	
	# Record starting position as home
	home_position = global_position
	
	# Generate some initial patrol points around the home position
	generate_patrol_points(5)
	
	# Find the player node - wait a moment to ensure scene is loaded
	call_deferred("find_player")
	
	# Start in idle state
	change_state(State.IDLE)
	
	if debug_mode:
		print("Minotaur initialized at position: ", global_position)

func _physics_process(delta):
	# Update state timer
	state_timer += delta
	
	# Re-check for player if not found
	if player == null:
		find_player()
		if player != null and debug_mode:
			print("Player found at: ", player.global_position)
	
	# Handle player detection and state changes
	if player:
		handle_player_awareness(delta)
	
	# Process current state behavior
	match current_state:
		State.IDLE:
			process_idle_state(delta)
		State.PATROL:
			process_patrol_state(delta)
		State.ALERT:
			process_alert_state(delta)
		State.FOLLOW:
			process_follow_state(delta)
		State.RETREAT:
			process_retreat_state(delta)
		State.AGGRESSIVE:
			process_aggressive_state(delta)
	
	# Apply movement
	if velocity != Vector2.ZERO:
		move_and_slide()
	
	# Update animations
	play_animation()
	
	# Debug logging
	if debug_mode and Engine.get_frames_drawn() % 60 == 0:  # Log every 60 frames
		print("Minotaur state: ", State.keys()[current_state], 
			  " - Position: ", global_position,
			  " - Velocity: ", velocity)
		if player:
			print("Distance to player: ", global_position.distance_to(player.global_position))

func process_idle_state(delta):
	velocity = Vector2.ZERO
	
	# After idle time, switch to patrol
	if state_timer > idle_time:
		change_state(State.PATROL)

func process_patrol_state(delta):
	if patrol_points.size() == 0:
		generate_patrol_points(3)
	
	# Move toward the current patrol point
	var target = patrol_points[current_patrol_point]
	var direction = (target - global_position).normalized()
	velocity = direction * patrol_speed
	
	# Check if reached current patrol point
	if global_position.distance_to(target) < patrol_point_reach_distance:
		current_patrol_point = (current_patrol_point + 1) % patrol_points.size()
		
		# 30% chance to become idle after reaching a patrol point
		if rng.randf() < 0.3:
			change_state(State.IDLE)
	
	# After patrolling for a while, go back to idle
	if state_timer > patrol_time:
		change_state(State.IDLE)

func process_alert_state(delta):
	# Face the player
	if player:
		var direction = (player.global_position - global_position).normalized()
		# Just turn to face but don't move
		velocity = Vector2.ZERO
		
		if debug_mode and state_timer < 0.1:
			print("ALERT: Minotaur noticed player")
		
		# After being alert for a set time, decide whether to follow
		if state_timer > alert_time:
			decision_timer = 0
			
			# Chance to follow the player
			if rng.randf() < follow_chance:
				if debug_mode:
					print("Decided to FOLLOW player")
				change_state(State.FOLLOW)
			else:
				if debug_mode:
					print("Decided to RETREAT from player")
				change_state(State.RETREAT)

func process_follow_state(delta):
	if player:
		# Update time spent following
		time_following += delta
		
		# Check if should become aggressive after following for too long
		if time_following > aggression_threshold && rng.randf() < aggression_chance:
			if debug_mode:
				print("Became AGGRESSIVE after following too long")
			change_state(State.AGGRESSIVE)
			return
		
		# Check if player is too far away to continue following
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player > follow_radius:
			if debug_mode:
				print("Player too far away, RETREATING")
			change_state(State.RETREAT)
			return
		
		# Randomly decide to inspect something interesting
		if !is_inspecting && rng.randf() < inspection_chance * delta:
			if debug_mode:
				print("Stopping to INSPECT something interesting")
			start_inspection()
			return
		
		# If currently inspecting something
		if is_inspecting:
			process_inspection(delta)
			return
		
		# Normal following behavior
		if distance_to_player > personal_space:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * follow_speed
			if debug_mode and Engine.get_frames_drawn() % 60 == 0:
				print("Following player - distance: ", distance_to_player)
		else:
			# Maintain personal space
			velocity = Vector2.ZERO
			if debug_mode and Engine.get_frames_drawn() % 60 == 0:
				print("Maintaining personal space")

func process_retreat_state(delta):
	# Reset follow timer when retreating
	time_following = 0
	
	# Move back to home territory
	var direction = (home_position - global_position).normalized()
	velocity = direction * patrol_speed
	
	# If close to home, return to patrol state
	if global_position.distance_to(home_position) < patrol_point_reach_distance:
		if debug_mode:
			print("Reached home, returning to PATROL")
		change_state(State.PATROL)

func process_aggressive_state(delta):
	if player:
		# Chase the player
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * chase_speed
		
		if debug_mode and Engine.get_frames_drawn() % 60 == 0:
			print("Chasing player aggressively")
		
		# If lost sight of player or got too far, retreat
		if global_position.distance_to(player.global_position) > follow_radius * 1.5:
			if debug_mode:
				print("Lost player during chase, RETREATING")
			change_state(State.RETREAT)
	else:
		if debug_mode:
			print("Lost player reference, RETREATING")
		change_state(State.RETREAT)

func handle_player_awareness(delta):
	if !player:
		return
		
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Detect player when close enough
	if (current_state == State.IDLE || current_state == State.PATROL) and distance_to_player < detect_radius:
		if debug_mode:
			print("Player detected at distance: ", distance_to_player)
		change_state(State.ALERT)
	
	# Lose interest if player is too far away while following
	elif current_state == State.FOLLOW and distance_to_player > follow_radius:
		if debug_mode:
			print("Player too far away, losing interest")
		change_state(State.RETREAT)

func start_inspection():
	is_inspecting = true
	inspection_timer = 0
	
	# Create a point to inspect near current position
	var inspection_offset = Vector2(
		rng.randf_range(-40, 40),
		rng.randf_range(-40, 40)
	)
	inspection_position = global_position + inspection_offset
	
	# Stop moving
	velocity = Vector2.ZERO

func process_inspection(delta):
	inspection_timer += delta
	
	# When finished inspecting, resume following
	if inspection_timer > curious_inspection_time:
		if debug_mode:
			print("Finished inspecting, resuming follow")
		is_inspecting = false
		# No need to change state, already in FOLLOW state

func change_state(new_state):
	if debug_mode:
		print("Minotaur changing state: ", State.keys()[current_state], " -> ", State.keys()[new_state])
	
	previous_state = current_state
	current_state = new_state
	state_timer = 0
	
	# Reset parameters based on new state
	match new_state:
		State.IDLE:
			pass
		State.PATROL:
			pass
		State.ALERT:
			is_inspecting = false
		State.FOLLOW:
			is_inspecting = false
		State.RETREAT:
			time_following = 0
			is_inspecting = false
		State.AGGRESSIVE:
			is_inspecting = false

func generate_patrol_points(count):
	patrol_points.clear()
	
	for i in range(count):
		var random_offset = Vector2(
			rng.randf_range(-generate_patrol_range, generate_patrol_range),
			rng.randf_range(-generate_patrol_range, generate_patrol_range)
		)
		patrol_points.append(home_position + random_offset)
	
	current_patrol_point = 0
	
	if debug_mode:
		print("Generated ", count, " patrol points around ", home_position)

func play_animation():
	var anim_to_play = "idle"
	
	match current_state:
		State.IDLE:
			anim_to_play = "idle"
		State.PATROL:
			if velocity.x > 0:
				anim_to_play = "idle"  # Replace with walk/run animations when available
			elif velocity.x < 0:
				anim_to_play = "idle"  # Replace with walk/run animations when available
			else:
				anim_to_play = "idle"
		State.ALERT:
			anim_to_play = "idle"  # Replace with alert animation when available
		State.FOLLOW:
			if is_inspecting:
				anim_to_play = "idle"  # Replace with inspect animation when available
			else:
				anim_to_play = "idle"  # Replace with follow animation when available
		State.RETREAT:
			anim_to_play = "idle"  # Replace with retreat animation when available
		State.AGGRESSIVE:
			anim_to_play = "idle"  # Replace with aggressive/attack animation when available
	
	$AnimatedSprite2D.play(anim_to_play)

func find_player():
	# Try multiple methods to find the player
	
	# Method 1: Check for nodes in "player" group
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		player = player_nodes[0]  # Get the first player
		if debug_mode:
			print("Found player via group: ", player)
		return
	
	# Method 2: Try to find by node path
	if player == null:
		if has_node("/root/game_world/Player") or has_node("/root/Player"):
			player = get_node_or_null("/root/game_world/Player") if has_node("/root/game_world/Player") else get_node_or_null("/root/Player")
			if player and debug_mode:
				print("Found player via node path: ", player)
			return
	
	# Method 3: Search for any node with "player" in the name
	if player == null:
		var root = get_tree().root
		player = find_player_recursive(root)
		if player and debug_mode:
			print("Found player via recursive search: ", player)
		return
	
	# Method 4: Last resort - find any node with player() method
	if player == null:
		var potential_players = get_tree().get_nodes_in_group("CharacterBody2D")
		for potential in potential_players:
			if potential.has_method("player") and potential != self:
				player = potential
				if debug_mode:
					print("Found player via player() method: ", player)
				return
	
	if player == null and debug_mode:
		print("Could not find player node!")

func find_player_recursive(node):
	# Check if this node is a potential player
	if node.name.to_lower().contains("player") and node is CharacterBody2D:
		return node
	
	# Check all children
	for child in node.get_children():
		var result = find_player_recursive(child)
		if result:
			return result
	
	return null
