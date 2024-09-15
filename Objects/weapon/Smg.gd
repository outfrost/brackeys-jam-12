extends Node3D

signal done_firing

@onready var bullet_tracer: MeshInstance3D = %BulletTracer

var firing: bool = false
var time_elapsed: float = 0.0

func _process(delta: float) -> void:
	if firing:
		if (
			is_between(time_elapsed, 0.5, 0.57)
			|| is_between(time_elapsed, 0.6, 0.67)
			|| is_between(time_elapsed, 0.7, 0.77)
			|| is_between(time_elapsed, 0.8, 0.87)
		):
			bullet_tracer.show()
		else:
			bullet_tracer.hide()

		time_elapsed += delta
		if time_elapsed >= 0.9:
			firing = false
			bullet_tracer.hide()
			done_firing.emit()

func fire(length: float) -> void:
	bullet_tracer.scale.y = length
	bullet_tracer.position.z = - 0.5 * length
	firing = true
	time_elapsed = 0.0

func is_between(v: float, start: float, end: float) -> bool:
	return v >= start && v <= end
