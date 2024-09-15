class_name SelectionArea
extends Area3D

signal selected

func enable(v: bool) -> void:
	$CollisionShape3D.disabled = !v
	if !v:
		$SelectionVis.hide()

func _input_event(_camera, event: InputEvent, _event_position, _normal, _shape_idx) -> void:
	if (
		event is InputEventMouseButton
		&& event.button_index == MOUSE_BUTTON_LEFT
		&& event.is_pressed()
	):
		selected.emit()

func _mouse_enter() -> void:
	$SelectionVis.show()

func _mouse_exit() -> void:
	$SelectionVis.hide()
