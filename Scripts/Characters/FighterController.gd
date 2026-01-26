extends CharacterBody2D

@export var PlayerId: int = 1 # 1 or 2
@export var Speed: float = 300.0
@export var JumpVelocity: float = -400.0
@export var Acceleration: float = 1500.0
@export var TurnAcceleration: float = 3000.0 # Faster acceleration when turning
@export var Friction: float = 1000.0
@export var AirResistance: float = 200.0
@export var BounceForce: float = 200.0

var gravity: float = 980.0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	var input_prefix = "p%d_" % PlayerId

	# Handle Jump.
	if Input.is_action_just_pressed(input_prefix + "up") and is_on_floor():
		velocity.y = JumpVelocity
	
	# Jump Cut (Variable Jump Height)
	if Input.is_action_just_released(input_prefix + "up") and velocity.y < 0:
		velocity.y *= 0.5

	# Get the input direction.
	var direction := Input.get_axis(input_prefix + "left", input_prefix + "right")
	
	if direction != 0:
		# Determine if we are turning (input is opposite to movement)
		var is_turning: bool = sign(direction) != sign(velocity.x) and abs(velocity.x) > 0.1
		var accel_to_use: float = TurnAcceleration if is_turning else Acceleration

		velocity.x = move_toward(velocity.x, direction * Speed, accel_to_use * delta)
	else:
		var deceleration: float = Friction if is_on_floor() else AirResistance
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

	move_and_slide()

	# Handle collision with other players (Bounce/Repulsion)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is CharacterBody2D:
			var bounce_direction = collision.get_normal()
			velocity += bounce_direction * BounceForce
