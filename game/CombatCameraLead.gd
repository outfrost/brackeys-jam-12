extends Node3D

const SPEED: float = 8.0

var camera_anchor: Node3D
var limits: Region3i
var enabled: bool = false

func _process(delta: float) -> void:
	if !enabled:
		return

	var input_dir: = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: = Vector3(input_dir.x, 0, input_dir.y).normalized()

	if camera_anchor:
		direction = direction.rotated(Vector3.UP, camera_anchor.rotation.y)

	position = limits.clamp_point(position + (direction * SPEED * delta))
