extends Node3D

func open():
	if $Pane.get_rotation_degrees().y == 0:
		$Pane.rotate_y(deg_to_rad(90))

func close():
	if $Pane.get_rotation_degrees().y != 0:
		$Pane.rotate_y(deg_to_rad(0))
