extends CharacterBody3D

const SPEED: float = 1.0
const ACCEL: float = 8.0
const JUMP_VELOCITY: float = 3.0

func _physics_process(delta: float) -> void:
	if !is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir: = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCEL * delta)
	velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCEL * delta)

	move_and_slide()
