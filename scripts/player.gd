extends CharacterBody2D

var speed = 100
var player_state

func _physics_process(delta):
	var direction = Input.get_vector("run_left", "run_right", "run_up", "run_down")

	if direction.x == 0 and direction.y == 0:
		player_state = "idle"
	elif direction.x != 0 or direction.y != 0:
		player_state = "running"

	velocity = direction * speed
	move_and_slide()

	play_animation(direction)

func play_animation(dir):
	if player_state == "idle":
		$AnimatedSprite2D.play("idle")
	if player_state == "running":
		if dir.y == -1:
			$AnimatedSprite2D.play("run-w")
		if dir.x == 1:
			$AnimatedSprite2D.play("run-d")
		if dir.y == 1:
			$AnimatedSprite2D.play("run-s")
		if dir.x == -1:
			$AnimatedSprite2D.play("run-a")
		
		if dir.x > 0.5 and dir.y < -0.5:
			$AnimatedSprite2D.play("run-d")
		if dir.x > 0.5 and dir.y > 0.5:
			$AnimatedSprite2D.play("run-d")
		if dir.x < -0.5 and dir.y > 0.5:
			$AnimatedSprite2D.play("run-a")
		if dir.x < -0.5 and dir.y < -0.5:
			$AnimatedSprite2D.play("run-a")

func player():
	pass
