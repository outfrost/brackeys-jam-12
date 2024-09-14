class_name RaycastVis
extends MeshInstance3D

var target: = Vector3.ZERO
var colour: = Color.BLACK

@onready var mat: = StandardMaterial3D.new()
@onready var ball: = $Ball

func _ready() -> void:
	if !OS.has_feature("debug"):
		set_process(false)
		return
	mesh = ImmediateMesh.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ball.mesh = ball.mesh.duplicate()
	ball.mesh.surface_set_material(0, mat)

func _process(delta: float) -> void:
	mat.albedo_color = colour
	var target_local: = global_transform.inverse() * target
	var m: ImmediateMesh = mesh as ImmediateMesh
	m.clear_surfaces()
	m.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	m.surface_add_vertex(Vector3.ZERO)
	m.surface_add_vertex(target_local)
	m.surface_end()
	ball.position = target_local

func update_vis(target: Vector3, colour: Color) -> void:
	self.target = target
	self.colour = colour
