@tool
extends EditorScript

func _run() -> void:
	var SceneRoot = EditorInterface.get_edited_scene_root()
	var nodes: = SceneRoot.find_children("CollisionShape3D*")
	for node in nodes:
		if !node:
			print("node is not node")
		var shape: ConvexPolygonShape3D = node.shape
		for i in shape.points.size():
			shape.points[i] = node.transform * shape.points[i]
		node.transform = Transform3D.IDENTITY
