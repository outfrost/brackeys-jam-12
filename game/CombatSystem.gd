extends Node

signal win
signal loss

@onready var player_ui: Control = $PlayerUI
@onready var enemy_ui: Control = $EnemyUI
@onready var name_label: Label = %NameLabel
@onready var ap_label: Label = %APLabel
@onready var end_turn_button: Button = %EndTurnButton

var grid: CombatGrid
var camera_lead: Node3D
var ally_actors: Array[Actor] = []
var enemy_actors: Array[Actor] = []

var player_turn: bool = true
var actor_idx: int = 0

func _ready() -> void:
	player_ui.hide()
	enemy_ui.hide()
	end_turn_button.pressed.connect(player_turn_finished)

func begin_combat(level: Node3D) -> void:
	grid = level.get_node(^"CombatGrid")
	assert(grid)
	grid.move_ordered.connect(actor_move_ordered)

	for actor in grid.actors:
		if actor.player:
			ally_actors.append(actor)
		else:
			enemy_actors.append(actor)

	enemy_actors.shuffle()

	begin_turn()

func begin_turn() -> void:
	grid.select_actor(null)
	grid.reset_display()
	player_ui.hide()
	enemy_ui.hide()
	if player_turn:
		if ally_actors.size() == 0:
			loss.emit()
			return

		for actor in ally_actors:
			actor.action_points = actor.starting_action_points

		var actor: = ally_actors[actor_idx]
		name_label.text = actor.actor_name
		ap_label.text = "AP %d/%d" % [actor.action_points, actor.starting_action_points]
		player_ui.show()

		grid.select_actor(actor)
		grid.show_available_moves()

		camera_lead.global_position = actor.global_position + Vector3(0.5, 0.0, 0.5)
	else:
		if enemy_actors.size() == 0:
			win.emit()
			return

		for actor in enemy_actors:
			actor.action_points = actor.starting_action_points

		var actor: = enemy_actors[actor_idx]
		enemy_ui.show()

		grid.select_actor(actor)

		camera_lead.global_position = actor.global_position + Vector3(0.5, 0.0, 0.5)

func actor_move_ordered(pos: Vector3i) -> void:
	var actor: Actor

	if player_turn:
		actor = ally_actors[actor_idx]
	else:
		actor = enemy_actors[actor_idx]

	if actor.moving:
		return

	var path: = grid.get_grid_path_to(pos)
	if !path:
		push_error("unable to initiate move: path does not exist")
	print(path.steps)

	actor.begin_move(path)
	actor.grid_pos = pos
	grid.show_available_moves()

	await actor.done_moving
	if player_turn:
		check_combat_state()

func check_combat_state() -> void:
	if ally_actors.size() == 0:
		loss.emit()
		return
	if enemy_actors.size() == 0:
		win.emit()
		return

	if player_turn:
		var points_left: = false
		for actor in ally_actors:
			if actor.action_points > 0:
				points_left = true
				break
		if !points_left:
			player_turn_finished()
	else:
		var points_left: = false
		for actor in enemy_actors:
			if actor.action_points > 0:
				points_left = true
				break
		if !points_left:
			enemy_turn_finished()

func player_turn_finished() -> void:
	player_turn = false
	actor_idx = 0
	begin_turn()

func enemy_turn_finished() -> void:
	player_turn = true
	actor_idx = 0
	begin_turn()
