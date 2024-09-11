@tool
extends EditorScript

func _run() -> void:
	var tex_dir: = get_editor_interface().get_resource_filesystem().get_filesystem_path("res://asset/texture/")
	for i in tex_dir.get_subdir_count():
		var subdir: = tex_dir.get_subdir(i)
		for k in subdir.get_file_count():
			var new_path: = subdir.get_file_path(k)
			new_path = new_path.substr(0, new_path.rfind("/") + 1)
			new_path += "%02d.png" % k
			print(subdir.get_file_path(k), " -> ", new_path)
			#DirAccess.rename_absolute(subdir.get_file_path(k), new_path)
