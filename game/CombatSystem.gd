extends Node

signal win
signal loss

@onready var player_ui: Control = $PlayerUI
@onready var enemy_ui: Control = $EnemyUI
@onready var name_label: Label = %NameLabel
@onready var ap_label: Label = %APLabel
@onready var attack_button: Button = %AttackButton
@onready var end_turn_button: Button = %EndTurnButton

var grid: CombatGrid
var camera_lead: Node3D
var ally_actors: Array[Actor] = []
var enemy_actors: Array[Actor] = []

var active: bool = false
var player_turn: bool = true
var actor_idx: int = 0

var in_attack_selection: bool = false

func _ready() -> void:
	player_ui.hide()
	enemy_ui.hide()
	attack_button.pressed.connect(attack_pressed)
	end_turn_button.pressed.connect(player_turn_finished)

func _unhandled_input(event: InputEvent) -> void:
	if !active:
		return

	if event.is_action_pressed("cycle_actor") && player_turn:
		get_viewport().set_input_as_handled()
		cycle_ally_actor()

func begin_combat(level: Node3D) -> void:
	grid = level.get_node(^"CombatGrid")
	assert(grid)
	grid.move_ordered.connect(actor_move_ordered)

	for actor in grid.actors:
		if actor.player:
			ally_actors.append(actor)
		else:
			enemy_actors.append(actor)
		actor.selected.connect(func(): actor_selected(actor))

	enemy_actors.shuffle()
	active = true

	begin_turn()

func begin_turn() -> void:
	grid.select_actor(null)
	grid.reset_display()
	player_ui.hide()
	enemy_ui.hide()
	for a in ally_actors:
		a.set_selectable(false)
	for a in enemy_actors:
		a.set_selectable(false)
	if player_turn:
		if ally_actors.size() == 0:
			loss.emit()
			return

		for actor in ally_actors:
			actor.action_points = actor.starting_action_points
			actor.set_selectable(true)

		var actor: = ally_actors[actor_idx]
		update_player_ui()
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

func cycle_ally_actor() -> void:
	select_ally_actor((actor_idx + 1) % ally_actors.size())

func select_ally_actor(idx: int) -> void:
	actor_idx = idx
	var actor: = ally_actors[actor_idx]
	update_player_ui()
	player_ui.show()

	grid.select_actor(actor)
	grid.show_available_moves()

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

	actor.begin_move(path)
	actor.grid_pos = pos
	update_player_ui()
	grid.show_available_moves()

	await actor.done_moving
	if player_turn:
		check_combat_state()

func attack_pressed() -> void:
	if !player_turn:
		return

	for actor in ally_actors:
		actor.set_selectable(false)
	for actor in enemy_actors:
		actor.set_selectable(true)

	grid.reset_display()
	in_attack_selection = true

func actor_selected(actor: Actor) -> void:
	if in_attack_selection && actor in enemy_actors:
		for a in enemy_actors:
			a.set_selectable(false)
		in_attack_selection = false
		attack_button.disabled = true

		ally_actors[actor_idx].attack(actor)
		await ally_actors[actor_idx].done_attacking

		update_player_ui()
		grid.show_available_moves()
		for a in ally_actors:
			a.set_selectable(true)
	elif !in_attack_selection && player_turn && actor in ally_actors:
		select_ally_actor(ally_actors.find(actor))

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

func update_player_ui() -> void:
	var actor: = ally_actors[actor_idx]
	name_label.text = actor.actor_name
	ap_label.text = "AP %d/%d" % [actor.action_points, actor.starting_action_points]
	attack_button.disabled = actor.action_points < Actor.ATTACK_AP_COST
