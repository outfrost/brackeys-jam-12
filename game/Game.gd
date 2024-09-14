class_name Game
extends Node

const LEVEL_SCN: PackedScene = preload("res://scene/Level01.tscn")
const OVERHEAD_CAMERA_SCN: PackedScene = preload("res://game/OverheadCamera.tscn")
const COMBAT_CAMERA_LEAD_SCN: PackedScene = preload("res://game/CombatCameraLead.tscn")
const COMBAT_SYSTEM_SCN: PackedScene = preload("res://game/CombatSystem.tscn")
const BEANS_SCN: PackedScene = preload("res://actor/pc/Beans.tscn")

@onready var main_menu: Control = $UI/MainMenu
@onready var transition_screen: TransitionScreen = $UI/TransitionScreen
@onready var world_container: Node3D = $WorldContainer

var level: Node3D
var overhead_camera
var combat_camera_lead
var combat_grid: CombatGrid
var combat_system

var debug: RefCounted

func _ready() -> void:
	if OS.has_feature("debug") && FileAccess.file_exists("res://debug.gd"):
		var debug_script: GDScript = load("res://debug.gd")
		if debug_script:
			debug = debug_script.new(self)
			debug.startup()

	main_menu.start_game.connect(on_start_game)
	Harbinger.subscribe("stealth_target_detected", stealth_target_detected)
	Harbinger.subscribe("stealth_objective_reached", stealth_objective_reached)

func _process(delta: float) -> void:
	Irid.text_overlay.display_public("fps %d" % Performance.get_monitor(Performance.TIME_FPS))

	if Input.is_action_just_pressed("menu"):
		back_to_menu()

func on_start_game() -> void:
	main_menu.hide()

	level = LEVEL_SCN.instantiate()
	world_container.add_child(level)
	combat_grid = level.get_node(^"CombatGrid")
	var beans_spawn: Node3D = level.get_node(^"BeansSpawn")

	overhead_camera = OVERHEAD_CAMERA_SCN.instantiate()
	world_container.add_child(overhead_camera)
	overhead_camera.global_position = beans_spawn.global_position

	combat_camera_lead = COMBAT_CAMERA_LEAD_SCN.instantiate()
	world_container.add_child(combat_camera_lead)
	combat_camera_lead.limits = combat_grid.grid_limits
	combat_camera_lead.camera_anchor = overhead_camera.anchor

	combat_system = COMBAT_SYSTEM_SCN.instantiate()
	world_container.add_child(combat_system)
	combat_system.camera_lead = combat_camera_lead

	var beans: = BEANS_SCN.instantiate()
	level.add_child(beans)
	beans.global_transform = beans_spawn.global_transform
	beans.camera_anchor = overhead_camera.anchor
	Harbinger.dispatch_deferred("stealth_track_target", [beans])

	overhead_camera.follow = beans

func back_to_menu() -> void:
	for child in world_container.get_children():
		child.queue_free()
	overhead_camera = null
	main_menu.show()

func stealth_target_detected(_ignore) -> void:
	back_to_menu()

func stealth_objective_reached(_ignore) -> void:
	var tmp_camera_pos: = level.get_node(^"StealthEndCameraPos")
	overhead_camera.follow = tmp_camera_pos
	overhead_camera.target_rotation = TAU / 8.0
	overhead_camera.target_zoom_dist = 4.0
	overhead_camera.controls_enabled = false

	await get_tree().create_timer(5.0).timeout

	combat_grid.prepare_combat()
	combat_system.begin_combat(level)
	overhead_camera.controls_enabled = true
	overhead_camera.follow = combat_camera_lead
	combat_camera_lead.enabled = true
