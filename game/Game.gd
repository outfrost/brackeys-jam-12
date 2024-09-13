class_name Game
extends Node

const LEVEL_SCN: PackedScene = preload("res://scene/Level01.tscn")
const OVERHEAD_CAMERA_SCN: PackedScene = preload("res://game/OverheadCamera.tscn")
const BEANS_SCN: PackedScene = preload("res://actor/Beans.tscn")

@onready var main_menu: Control = $UI/MainMenu
@onready var transition_screen: TransitionScreen = $UI/TransitionScreen
@onready var world_container: Node3D = $WorldContainer

var overhead_camera

var debug: RefCounted

func _ready() -> void:
	if OS.has_feature("debug") && FileAccess.file_exists("res://debug.gd"):
		var debug_script: GDScript = load("res://debug.gd")
		if debug_script:
			debug = debug_script.new(self)
			debug.startup()

	main_menu.start_game.connect(on_start_game)

func _process(delta: float) -> void:
	Irid.text_overlay.display_public("fps %d" % Performance.get_monitor(Performance.TIME_FPS))
	pass

	if Input.is_action_just_pressed("menu"):
		back_to_menu()

func on_start_game() -> void:
	main_menu.hide()
	var level: = LEVEL_SCN.instantiate()
	world_container.add_child(level)
	overhead_camera = OVERHEAD_CAMERA_SCN.instantiate()
	world_container.add_child(overhead_camera)
	var beans: = BEANS_SCN.instantiate()
	level.add_child(beans)
	beans.global_transform = level.get_node(^"BeansSpawn").global_transform
	beans.camera_anchor = overhead_camera.anchor
	overhead_camera.follow = beans

func back_to_menu() -> void:
	for child in world_container.get_children():
		child.queue_free()
	overhead_camera = null
	main_menu.show()
