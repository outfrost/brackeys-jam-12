extends GridMap
# there are two coordinate spaces in use here:
# * grid space is 3D, with distances same as in world
# * astar space is 2D, with doubled distances,
#   because of the addition of half-cells to account for obstacles in pathfinding

const TILE_RUNTIME_HIDDEN: int = 0
const TILE_RUNTIME_VISIBLE: int = 1
const TILE_BASE: int = 2
const TILE_E: int = 3
const TILE_EW: int = 4
const TILE_N: int = 5
const TILE_NE: int = 6
const TILE_NWE: int = 7
const TILE_NS: int = 8
const TILE_NSE: int = 9
const TILE_NSW: int = 10
const TILE_NW: int = 11
const TILE_S: int = 12
const TILE_SE: int = 13
const TILE_SWE: int = 14
const TILE_SW: int = 15
const TILE_W: int = 16

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
		min_coords.x = minf(min_coords.x, pos.x)
		min_coords.y = minf(min_coords.y, pos.z)
		max_coords.x = maxf(max_coords.x, pos.x)
		max_coords.y = maxf(max_coords.y, pos.z)

	# adding (1, 1) because AStarGrid2D uses Rect2i.size as end-exclusive
	max_coords += Vector2i.ONE

	# double the cell count in both axes just for astar
	# (half-cells are for walls and other thin obstacles)
	astar.region = Rect2i(min_coords * 2, (max_coords - min_coords) * 2)
	astar.update()

	# prevent navigating to areas not marked on GridMap
	astar.fill_solid_region(astar.region, true)

	for i in max_coords.x - min_coords.x:
		for k in max_coords.y - min_coords.y:
			var pos := Vector3i(i + min_coords.x, 0, k + min_coords.y)
			var tile: = get_cell_item(pos)

			# unblock tile cells, and half-cells towards +x and +z,
			# based on whether there are obstacles east and south
			match tile:
				TILE_BASE, TILE_N, TILE_NW, TILE_W:
					astar.set_point_solid(grid_to_astar(pos), false)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(0, 1), false)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(1, 1), false)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(1, 0), false)
				TILE_E, TILE_EW, TILE_NE, TILE_NWE:
					astar.set_point_solid(grid_to_astar(pos), false)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(0, 1), false)
				TILE_NS, TILE_NSW, TILE_S, TILE_SW:
					astar.set_point_solid(grid_to_astar(pos), false)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(1, 0), false)
				TILE_NSE, TILE_SE, TILE_SWE:
					astar.set_point_solid(grid_to_astar(pos), false)

			# block half-cells towards -x and -z
			# that may have previously been unblocked
			match tile:
				TILE_N, TILE_NE, TILE_NS, TILE_NSE:
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(-1, -1), true)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(0, -1), true)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(1, -1), true)
				TILE_NW, TILE_NWE, TILE_NSW:
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(-1, 1), true)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(-1, 0), true)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(-1, -1), true)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(0, -1), true)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(1, -1), true)
				TILE_W, TILE_EW, TILE_SW:
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(-1, 1), true)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(-1, 0), true)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(-1, -1), true)
				TILE_E:
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(1, -1), true)
				TILE_S:
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(-1, 1), true)
				TILE_SE:
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(-1, 1), true)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(1, -1), true)
				TILE_SWE:
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(-1, 1), true)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(-1, 0), true)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(-1, -1), true)
					astar.set_point_solid(grid_to_astar(pos) + Vector2i(1, -1), true)

	var beans: Actor = (load("res://actor/Beans.tscn") as PackedScene).instantiate()
	add_child(beans)
	beans.grid_pos = Vector3i(-2, 0, -3)
	beans.action_points = 3

	await get_tree().create_timer(1.0).timeout
	#reset_display()

	select_actor(beans)
	await get_tree().create_timer(0.5).timeout
	show_available_moves()
	#await get_tree().create_timer(2.0).timeout
	#reset_display()

func select_actor(actor: Actor) -> void:
	selected_actor = actor

func show_available_moves() -> void:
	if !selected_actor:
		return

	var pos: = selected_actor.grid_pos
	if get_cell_item(pos) == INVALID_CELL_ITEM:
		return

	for cell in find_reachable_cells(pos, selected_actor.action_points):
		set_cell_item(cell, TILE_RUNTIME_VISIBLE)

func reset_display() -> void:
	for cell in get_used_cells():
		set_cell_item(cell, TILE_RUNTIME_HIDDEN)

func find_reachable_cells(start_pos: Vector3i, max_dist: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var start: = grid_to_astar(start_pos)

	var append_if_reachable: = func(end_pos: Vector3i):
		var end: = grid_to_astar(end_pos)
		if astar.is_in_boundsv(end) && !astar.is_point_solid(end):
			var path: = astar.get_id_path(start, end)
			if !path.is_empty() && calc_path_cost(path) <= max_dist:
				result.append(end_pos)

	for i in max_dist:
		append_if_reachable.call(start_pos + Vector3i(- (i + 1), 0, 0))
		append_if_reachable.call(start_pos + Vector3i(+ (i + 1), 0, 0))
		append_if_reachable.call(start_pos + Vector3i(0, 0, - (i + 1)))
		append_if_reachable.call(start_pos + Vector3i(0, 0, + (i + 1)))

		for k in max_dist:
			append_if_reachable.call(start_pos + Vector3i(- (i + 1), 0, - (k + 1)))
			append_if_reachable.call(start_pos + Vector3i(- (i + 1), 0, + (k + 1)))
			append_if_reachable.call(start_pos + Vector3i(+ (i + 1), 0, - (k + 1)))
			append_if_reachable.call(start_pos + Vector3i(+ (i + 1), 0, + (k + 1)))

	return result

func calc_path_cost(path: Array[Vector2i]) -> int:
	if path.size() < 2:
		return 0
	var cost: float = 0.0
	for i in path.size() - 1:
		cost += path[i].distance_to(path[i + 1])
	return ceili(cost / 2.0)

func grid_to_astar(v: Vector3i) -> Vector2i:
	return Vector2i(v.x << 1, v.z << 1)

func astar_to_grid(v: Vector2i) -> Vector3i:
	return Vector3i(v.x >> 1, 0, v.y >> 1)
