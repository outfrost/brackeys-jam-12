class_name DetectionProfile
extends Resource

@export_range(0.0, 180.0, 1.0, "radians_as_degrees") var fov: float = TAU / 4.0
@export_range(0.0, 20.0, 0.5, "or_greater") var los_range: float = 8.0
@export var los_sensitivity: float = 0.4
@export_range(0.0, 20.0, 0.5, "or_greater") var motion_range: float = 15.0
@export var motion_sensitivity: float = 0.8
@export var decay: float = 0.2
