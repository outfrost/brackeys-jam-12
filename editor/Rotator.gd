@tool
extends EditorScript

func _run() -> void:
	var SceneRoot = EditorInterface.get_edited_scene_root()
	var random = RandomNumberGenerator.new()
	random.randomize()
	for nodeI in SceneRoot.get_children():
		var current_rotation = (nodeI as Node3D).get_rotation_degrees()
		var new_rotation = Vector3(current_rotation.x, random.randf_range(0.0,90.0),current_rotation.z)
		print("Setting Y Rotation Node: ", nodeI, " to ", new_rotation.y)
		nodeI.set_rotation_degrees(new_rotation)
		
