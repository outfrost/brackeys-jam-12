extends Node3D

@onready var combat_grid: CombatGrid = $CombatGrid
@onready var combat_system = $CombatSystem
@onready var overhead_camera = $OverheadCamera
@onready var combat_camera_lead = $CombatCameraLead

func _ready() -> void:
	combat_camera_lead.limits = combat_grid.grid_limits
	combat_camera_lead.camera_anchor = overhead_camera.anchor
	combat_system.camera_lead = combat_camera_lead

	combat_grid.prepare_combat()
	combat_system.begin_combat(self)
	overhead_camera.controls_enabled = true
	overhead_camera.follow = combat_camera_lead
	combat_camera_lead.enabled = true
