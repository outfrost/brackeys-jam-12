extends Node3D

const POS_LERP_SPEED: float = 8.0
const ZOOM_LERP_SPEED: float = 8.0
const ZOOM_MIN_DIST: float = 1.0
const ZOOM_MAX_DIST: float = 8.0
const ROT_LERP_SPEED: float = 4.0

@onready var anchor: = $CameraAnchor
@onready var camera: = $CameraAnchor/Camera3D
@onready var target_rotation: float = anchor.rotation.y

var follow: Node3D
var target_zoom_dist: float = 4.0

func _process(delta: float) -> void:
	var pos_lerp_rate: float = clamp(POS_LERP_SPEED * delta, 0.0, 1.0)
	global_position = global_position.lerp(follow.global_position, pos_lerp_rate)

	var zoom_lerp_rate: float = clamp(ZOOM_LERP_SPEED * delta, 0.0, 1.0)
	camera.position.z = lerp(camera.position.z, target_zoom_dist, zoom_lerp_rate)

	var rot_lerp_rate: float = clamp(ROT_LERP_SPEED * delta, 0.0, 1.0)
	anchor.rotation.y = lerp_angle(anchor.rotation.y, target_rotation, rot_lerp_rate)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		target_zoom_dist = maxf(target_zoom_dist - 0.5, ZOOM_MIN_DIST)

	if event.is_action_pressed("zoom_out"):
		target_zoom_dist = minf(target_zoom_dist + 0.5, ZOOM_MAX_DIST)

	if event.is_action_pressed("rotate_left"):
		target_rotation = wrapf(target_rotation + (0.25 * TAU), - 0.5 * TAU, 0.5 * TAU)

	if event.is_action_pressed("rotate_right"):
		target_rotation = wrapf(target_rotation - (0.25 * TAU), - 0.5 * TAU, 0.5 * TAU)
