extends Node3D

func open():
	if $Pane1.get_rotation_degrees().y == 0:
		$Pane1.rotate_y(deg_to_rad(-90))
	if $Pane2.get_rotation_degrees().y ==180:
		$Pane2.rotate_y(deg_to_rad(90))

func close():
	if $Pane1.get_rotation_degrees().y != 0:
		$Pane1.rotate_y(deg_to_rad(0))
	if $Pane2.get_rotation_degrees().y !=180:
		$Pane2.rotate_y(deg_to_rad(180))
