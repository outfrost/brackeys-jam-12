class_name Actor
extends Node3D

signal done_moving

const VISUAL_MOVE_SPEED: float = 3.0

@export var player: bool = false
@export var actor_name: String
@export var starting_action_points: int
@export var can_move: bool = true
@export_range(0.0, 315.0, 45.0, "radians_as_degrees") var starting_rotation: float = 0.0

var grid_pos: Vector3i
var action_points: int
var moving: bool = false
var move_path: CombatGrid.GridPath = null
var move_path_idx: int = 0

func _ready() -> void:
	grid_pos = Vector3i(position)
	if get_child_count() == 0:
		return

	(get_child(0) as Node3D).rotation.y = starting_rotation

	if get_child(0).get("enabled"):
		get_child(0).enabled = false

func _process(delta: float) -> void:
	if moving:
		var dest: = Vector3(move_path.steps[move_path_idx])
		position = position.move_toward(dest, VISUAL_MOVE_SPEED * delta)
		if position.is_equal_approx(dest):
			move_path_idx += 1
			if move_path_idx >= move_path.steps.size():
				moving = false
				move_path = null
				done_moving.emit()
		else:
			(get_child(0) as Node3D).rotation.y = Vector3.FORWARD.signed_angle_to(dest - position, Vector3.UP)

func begin_move(path: CombatGrid.GridPath) -> void:
	if moving:
		return

	moving = true
	move_path = path
	move_path_idx = 0

	action_points = maxi(action_points - path.cost, 0)
