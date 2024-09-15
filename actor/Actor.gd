class_name Actor
extends Node3D

signal done_moving
signal done_attacking
signal selected
signal died

const VISUAL_MOVE_SPEED: float = 3.0
const ATTACK_AP_COST: int = 4.0
const SEL_AREA_SCN: PackedScene = preload("res://actor/SelectionArea.tscn")

@export var player: bool = false
@export var actor_name: String
@export var starting_action_points: int
@export var can_move: bool = true
@export var can_attack: bool = true
@export_range(0.0, 315.0, 45.0, "radians_as_degrees") var starting_rotation: float = 0.0

@onready var weapon: Node3D = find_child("Smg", true, false)

var grid_pos: Vector3i
var hp: int = 10
var action_points: int
var moving: bool = false
var move_path: CombatGrid.GridPath = null
var move_path_idx: int = 0
var attacking: bool = false
var attack_target: Vector3 = Vector3.ZERO
var selection_area: SelectionArea

func _ready() -> void:
	grid_pos = Vector3i(position)

	if get_child_count() == 0:
		return

	(get_child(0) as Node3D).rotation.y = starting_rotation

	selection_area = SEL_AREA_SCN.instantiate()
	add_child(selection_area)
	selection_area.enable(false)
	selection_area.position = Vector3(0.5, 0.0, 0.5)
	selection_area.selected.connect(func(): selected.emit())

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

func activate_combat() -> void:
	for node in find_children("*", "CollisionShape3D", true, false):
		node.disabled = true

	for child in get_children():
		if child.get("enabled"):
			child.enabled = false

func begin_move(path: CombatGrid.GridPath) -> void:
	if moving:
		return

	moving = true
	move_path = path
	move_path_idx = 0

	action_points = maxi(action_points - path.cost, 0)

func attack(target: Actor) -> void:
	action_points = maxi(action_points - ATTACK_AP_COST, 0)
	attack_target = target.position + Vector3(0.5, 0.0, 0.5)
	attacking = true

	(get_child(0) as Node3D).rotation.y = Vector3.FORWARD.signed_angle_to(
		target.position - (position),# + weapon.position),
		Vector3.UP
	)
	weapon.fire((target.position - position).length())

	await weapon.done_firing
	if attacking:
		attacking = false
		done_attacking.emit()

func take_damage(dmg: int) -> void:
	hp -= dmg
	if hp <= 0:
		died.emit()

func set_selectable(v: bool) -> void:
	selection_area.enable(v)
