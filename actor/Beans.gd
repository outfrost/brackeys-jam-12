extends CharacterBody3D

const SPEED: float = 1.0
const ACCEL: float = 8.0
const JUMP_VELOCITY: float = 3.0

@onready var visual: Node3D = $Visual
@onready var prev_transform: Transform3D = transform

var enabled: = true
var camera_anchor: Node3D

@onready var debug: = Irid.text_overlay.tracker(self)

func _ready() -> void:
	pass
	#debug.trace(^"prev_transform")
	#debug.trace(^"transform")

func _process(delta: float) -> void:
	# interpolate movement visually
	visual.transform = (
		transform.affine_inverse()
		* prev_transform.interpolate_with(transform, Engine.get_physics_interpolation_fraction())
	)

	#debug.display("visual:transform: %s" % Irid.text_overlay._str(visual.transform))

func _physics_process(delta: float) -> void:
	prev_transform = transform

	if !enabled:
		return

	if !is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir: = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: = Vector3(input_dir.x, 0, input_dir.y).normalized()

	if camera_anchor:
		direction = direction.rotated(Vector3.UP, camera_anchor.rotation.y)

	if direction.length_squared() > 0.05:
		var angle: = Vector3.FORWARD.signed_angle_to(direction, Vector3.UP)
		var slerp_rate: float = clamp(8.0 * (0.25 + 0.5 * (cos(angle - rotation.y) + 1.0)) * delta, 0.0, 1.0)
		rotation.y = lerp_angle(rotation.y, angle, slerp_rate)

	#rotation
	#var direction_local: = transform.basis * direction
	#if direction_local.length_squared() > 0.05:
		#var angle: = Vector3.FORWARD.signed_angle_to(direction_local, Vector3.UP)
		#DebugOverlay.display(str(angle))
#
		#var slerp_rate: float = clamp(8.0 * (0.25 + 0.5 * (cos(angle) + 1.0)) * delta, 0.0, 1.0)
		#var new_rotation_y: = lerp_angle(rotation.y, rotation.y + angle, slerp_rate)
#
		## prevent jitter/wiggle at low physics framerates
		#if abs(angle_difference(rotation.y, new_rotation_y)) > abs(angle):
			#new_rotation_y = rotation.y + angle
#
		#rotation.y = new_rotation_y

	velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCEL * delta)
	velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCEL * delta)

	move_and_slide()
