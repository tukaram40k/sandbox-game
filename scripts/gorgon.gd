extends CharacterBody2D

var speed = 100
var player_state

func _physics_process(delta):
	
	# var direction = Input.get_vector("run_left", "run_right", "run_up", "run_down")
	

	#if direction.x == 0 and direction.y == 0:
		#player_state = "idle"
	#elif direction.x != 0 or direction.y != 0:
		#player_state = "running"
		
	# держим в айдл стейте пока что
	player_state = "idle"

	if velocity != Vector2.ZERO:
		move_and_slide()

	play_animation()

func play_animation():
	if player_state == "idle":
		$AnimatedSprite2D.play("idle")

func player():
	pass
