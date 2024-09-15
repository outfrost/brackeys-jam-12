class_name Actor
extends Node3D

const VISUAL_MOVE_SPEED: float = 3.0

@export var player: bool = false
@export var actor_name: String
@export var grid_pos: Vector3i
@export var starting_action_points: int

var action_points: int
var moving: bool = false
var move_path: CombatGrid.GridPath = null
var move_path_idx: int = 0

func _process(delta: float) -> void:
	if moving:
		var dest: = Vector3(move_path.steps[move_path_idx])
		position = position.move_toward(dest, VISUAL_MOVE_SPEED * delta)
		if position.is_equal_approx(dest):
			move_path_idx += 1
			if move_path_idx >= move_path.steps.size():
				moving = false
				move_path = null

func begin_move(path: CombatGrid.GridPath) -> void:
	if moving:
		return

	moving = true
	move_path = path
	move_path_idx = 0

	action_points = maxi(action_points - path.cost, 0)
