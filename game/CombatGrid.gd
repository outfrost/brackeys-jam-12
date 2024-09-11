extends GridMap

var astar: = AStarGrid2D.new()
var selected_actor: Actor

func _ready() -> void:
	mesh_library.get_item_mesh(0).surface_set_material(0, load("res://material/invisible.tres"))

	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.jumping_enabled = true

	var used_cells: = get_used_cells()

	var min_coords: = Vector2i.ZERO
	var max_coords: = Vector2i.ZERO
	for pos in used_cells:
		min_coords.x = min(min_coords.x, pos.x)
		min_coords.y = min(min_coords.y, pos.z)
		max_coords.x = max(max_coords.x, pos.x)
		max_coords.y = max(max_coords.y, pos.z)

	astar.region = Rect2i(min_coords, max_coords - min_coords + Vector2i.ONE)
	astar.update()

	astar.fill_solid_region(astar.region, true)
	for pos in used_cells:
		astar.set_point_solid(Vector2i(pos.x, pos.z), false)

	var beans: Actor = (load("res://actor/Beans.tscn") as PackedScene).instantiate()
	add_child(beans)
	beans.grid_pos = Vector3i(1, 0, -1)
	beans.action_points = 3

	reset_display()

	select_actor(beans)
	await get_tree().create_timer(1.0).timeout
	show_available_moves()
	await get_tree().create_timer(2.0).timeout
	reset_display()

func select_actor(actor: Actor) -> void:
	selected_actor = actor

func show_available_moves() -> void:
	if !selected_actor:
		return

	var pos: = selected_actor.grid_pos
	if get_cell_item(pos) == INVALID_CELL_ITEM:
		return

	for cell in find_reachable_cells(pos, selected_actor.action_points):
		set_cell_item(cell, 1)

func reset_display() -> void:
	for cell in get_used_cells():
		set_cell_item(cell, 0)

func find_reachable_cells(start_pos: Vector3i, max_dist: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var start: = to2d(start_pos)

	var append_if_reachable: = func(end: Vector2i):
		if astar.is_in_boundsv(end) && !astar.is_point_solid(end):
			var path: = astar.get_id_path(start, end)
			if calc_path_cost(path) <= max_dist:
				result.append(to3d(end))

	for i in max_dist:
		append_if_reachable.call(start + Vector2i(- (i + 1), 0))
		append_if_reachable.call(start + Vector2i(+ (i + 1), 0))
		append_if_reachable.call(start + Vector2i(0, - (i + 1)))
		append_if_reachable.call(start + Vector2i(0, + (i + 1)))

		for k in max_dist:
			append_if_reachable.call(start + Vector2i(- (i + 1), - (k + 1)))
			append_if_reachable.call(start + Vector2i(- (i + 1), + (k + 1)))
			append_if_reachable.call(start + Vector2i(+ (i + 1), - (k + 1)))
			append_if_reachable.call(start + Vector2i(+ (i + 1), + (k + 1)))

	return result

func calc_path_cost(path: Array[Vector2i]) -> int:
	if path.size() < 2:
		return 0
	var cost: float = 0.0
	for i in path.size() - 1:
		cost += path[i].distance_to(path[i + 1])
	return ceili(cost)

func to2d(v: Vector3i) -> Vector2i:
	return Vector2i(v.x, v.z)

func to3d(v: Vector2i) -> Vector3i:
	return Vector3i(v.x, 0, v.y)
