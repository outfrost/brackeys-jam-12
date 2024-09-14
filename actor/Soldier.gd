extends CharacterBody3D

const RAYCAST_VIS_SCN: PackedScene = preload("res://actor/RaycastVis.tscn")
const DETECTION_RAY_CONE_ANGLE: float = TAU / 64.0
const DETECTION_RAY_CONE_ANGLE_STEPS: int = 2
const FOV_FORWARD_DIRECTION: = Vector3(0.0, -0.383, -0.924) # looking 22.5 deg down from straight ahead

@export var vision_sensor: Node3D

@export_group("Detection", "detection_")
@export var detection_profile: DetectionProfile

@onready var detection_ray_length: float = maxf(
	detection_profile.los_range,
	detection_profile.motion_range
)
@onready var num_rays: int = 1 + (DETECTION_RAY_CONE_ANGLE_STEPS * 6)
var raycast_vis: Array[RaycastVis]

var target: CharacterBody3D = null

var ray_idx: int = 0
var line_of_sight: bool = false
var los_last_ray_idx: int = 0
var los_distance: float = 0.0

var detected: float = 0.0
var target_last_pos: = Vector3.ZERO

@onready var debug: = Irid.text_overlay.tracker(self)

func _ready() -> void:
	Harbinger.subscribe("stealth_track_target", set_target)
	#Harbinger.subscribe("npc_reset", reset)

	for i in range(num_rays):
		var vis: = RAYCAST_VIS_SCN.instantiate()
		vision_sensor.add_child(vis)
		raycast_vis.append(vis)

	debug.trace("line_of_sight").trace("los_distance").trace("detected").trace("target_last_pos")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_draw_raycast"):
		for vis in raycast_vis:
			vis.visible = !vis.visible

func _physics_process(delta: float) -> void:
	if !target:
		detected = 0.0
		return

	#region perception
	var dir_to_target: = (target.global_position - vision_sensor.global_position).normalized()
	var dir: = dir_to_target
	var cone_angle_axis: = dir.cross(dir.rotated(Vector3.UP, 0.5)).normalized()
	dir = dir.rotated(
		cone_angle_axis,
		((ray_idx + 5) / 6) * (DETECTION_RAY_CONE_ANGLE / DETECTION_RAY_CONE_ANGLE_STEPS)
	)
	dir = dir.rotated(
		dir_to_target,
		((ray_idx + 5) % 6) * (TAU / 6.0)
	)

	var space_state: = get_world_3d().direct_space_state
	var query: = PhysicsRayQueryParameters3D.create(
		vision_sensor.global_position,
		vision_sensor.global_position + (dir * detection_ray_length)
	)
	#query.exclude = [get_rid()]
	var result: = space_state.intersect_ray(query)
	var fov_forward: = global_transform.basis * FOV_FORWARD_DIRECTION
	debug.display(rad_to_deg(fov_forward.angle_to(dir)))
	debug.display(rad_to_deg(detection_profile.fov))
	if result && fov_forward.angle_to(dir) < detection_profile.fov * 0.5:
		if result.collider == target:
			raycast_vis[ray_idx].update_vis(result.position, Color.GREEN)
			line_of_sight = true
			los_last_ray_idx = ray_idx
			target_last_pos = result.position
			los_distance = (result.position - vision_sensor.global_position).length()
		else:
			raycast_vis[ray_idx].update_vis(result.position, Color.ORANGE)
			if los_last_ray_idx == ray_idx:
				line_of_sight = false
	else:
		raycast_vis[ray_idx].update_vis(vision_sensor.global_position + (dir * detection_ray_length), Color.DARK_RED)
		if los_last_ray_idx == ray_idx:
				line_of_sight = false

	ray_idx = (ray_idx + 1) % num_rays
	#endregion

	#region detection
	if line_of_sight:
		var target_speed: = target.velocity.length()
		if los_distance <= detection_profile.los_range:
			detected += detection_profile.los_sensitivity * delta
		if los_distance <= detection_profile.motion_range:
			detected += target_speed * detection_profile.motion_sensitivity * delta
		if los_distance > detection_profile.los_range && los_distance > detection_profile.motion_range:
			detected -= detection_profile.decay * delta
	else:
		detected -= detection_profile.decay * delta

	detected = clampf(detected, 0.0, 1.0)

	if detected == 1.0:
		Harbinger.dispatch("stealth_target_detected", [])
	#endregion

func set_target(t) -> void:
	target = t[0]

func reset(_ignore) -> void:
	detected = 0.0
	line_of_sight = false
	ray_idx = 0
	los_last_ray_idx = 0
	target_last_pos = Vector3.ZERO
