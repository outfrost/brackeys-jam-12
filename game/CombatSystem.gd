extends Node

signal win
signal loss

@onready var player_ui: Control = $PlayerUI
@onready var enemy_ui: Control = $EnemyUI
@onready var name_label: Label = %NameLabel
@onready var ap_label: Label = %APLabel

var grid: CombatGrid
var camera_lead: Node3D
var ally_actors: Array[Actor] = []
var enemy_actors: Array[Actor] = []

var player_turn: bool = true
var actor_idx: int = 0

func _ready() -> void:
	player_ui.hide()
	enemy_ui.hide()

func begin_combat(level: Node3D) -> void:
	grid = level.get_node(^"CombatGrid")
	assert(grid)

	for actor in grid.actors:
		if actor.player:
			ally_actors.append(actor)
		else:
			enemy_actors.append(actor)

	enemy_actors.shuffle()

	begin_turn()

func begin_turn() -> void:
	player_ui.hide()
	enemy_ui.hide()
	if player_turn:
		if ally_actors.size() == 0:
			loss.emit()
			return
		var actor: = ally_actors[actor_idx]
		name_label.text = actor.actor_name
		ap_label.text = "AP %d/%d" % [actor.action_points, actor.starting_action_points]
		player_ui.show()
		camera_lead.global_position = actor.global_position + Vector3(0.5, 0.0, 0.5)
	else:
		if enemy_actors.size() == 0:
			win.emit()
			return
		var actor: = enemy_actors[actor_idx]
		enemy_ui.show()
		camera_lead.global_position = actor.global_position + Vector3(0.5, 0.0, 0.5)
