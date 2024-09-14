extends Node3D

@onready var area: Area3D = $Area3D
@onready var goober_pos: Node3D = $GooberPos

var target: Node3D
var target_in_area: bool = false

func _ready() -> void:
	Harbinger.subscribe("stealth_track_target", stealth_track_target)
	area.body_entered.connect(body_entered)
	area.body_exited.connect(body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("use") && target_in_area && target:
		get_viewport().set_input_as_handled()
		target.global_transform = goober_pos.global_transform
		Harbinger.dispatch("stealth_objective_reached", [])

func stealth_track_target(t) -> void:
	target = t[0]

func body_entered(body: Node3D) -> void:
	if body == target:
		target_in_area = true

func body_exited(body: Node3D) -> void:
	if body == target:
		target_in_area = false
