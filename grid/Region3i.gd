class_name Region3i
extends RefCounted

@export var position: Vector3i
@export var size: Vector3i

func _init(position: Vector3i, size: Vector3i) -> void:
	self.position = position
	self.size = size

static func from_coords(pos_x: int, pos_y: int, pos_z: int, size_x: int, size_y: int, size_z: int) -> Region3i:
	return Region3i.new(Vector3i(pos_x, pos_y, pos_z), Vector3i(size_x, size_y, size_z))

# Returns whether point is within [position, position + size]
# (region is end-inclusive)
func contains_point(point: Vector3i) -> bool:
	return (
		point.x >= position.x
		&& point.x <= position.x + size.x
		&& point.y >= position.y
		&& point.y <= position.y + size.y
		&& point.z >= position.z
		&& point.z <= position.z + size.z
	)

func clamp_point(point: Vector3) -> Vector3:
	return Vector3(
		clampf(point.x, position.x, position.x + size.x),
		clampf(point.y, position.y, position.y + size.y),
		clampf(point.z, position.z, position.z + size.z)
	)
