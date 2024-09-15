class_name CombatGrid
extends GridMap
# there are two coordinate spaces in use here:
# * grid space is 3D, with distances same as in world
# * astar space is 2D, with doubled distances,
#   because of the addition of half-cells to account for obstacles in pathfinding

signal move_ordered(pos)

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
const TILE_RUNTIME_HIGHLIGHT: int = 17

class GridPath:
	var cost: int
	var steps: Array[Vector3]

	func _init(cost: int, steps: Array[Vector3]) -> void:
		self.cost = cost
		self.steps = steps

var astar: = AStarGrid2D.new()
var actors: Array[Actor] = []
var selected_actor: Actor
var grid_limits: Region3i

func _ready() -> void:
	mesh_library.get_item_mesh(0).surface_set_material(0, load("res://material/invisible.tres"))

	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.jumping_enabled = true

	var used_cells: = get_used_cells()

	var area_parent: = Node3D.new()
	add_child(area_parent)
	var box_shape: = BoxShape3D.new()
	box_shape.size = Vector3(1.0, 0.2, 1.0)

	var min_coords: = Vector2i.ZERO
	var max_coords: = Vector2i.ZERO

	for pos in used_cells:
		var area: = Area3D.new()
		area.position = Vector3(pos)
		area.input_ray_pickable = true
		area_parent.add_child(area)
		var col_shape: = CollisionShape3D.new()
		col_shape.position = Vector3(0.5, 0.0, 0.5)
		col_shape.shape = box_shape
		area.add_child(col_shape)

		area.mouse_entered.connect(func(): self.cell_hovered(pos))
		area.mouse_exited.connect(func(): self.cell_unhovered(pos))
		area.input_event.connect(func(_camera, event: InputEvent, _event_position, _normal, _shape_idx):
			self.cell_input_event(event, pos)
		)

		min_coords.x = minf(min_coords.x, pos.x)
		min_coords.y = minf(min_coords.y, pos.z)
		max_coords.x = maxf(max_coords.x, pos.x)
		max_coords.y = maxf(max_coords.y, pos.z)

	grid_limits = Region3i.from_coords(
		min_coords.x, 0, min_coords.y,
		max_coords.x - min_coords.x, 0, max_coords.y - min_coords.y
	)

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

	reset_display()
	show()

func prepare_combat() -> void:
	for child in get_children():
		if child is Actor:
			actors.append(child)
			child.show()

func get_actors_in_region(region: Region3i) -> Array[Actor]:
	var result: Array[Actor] = []
	for actor in actors:
		if region.contains_point(actor.grid_pos):
			result.append(actor)
	return result

func get_actors_in_range(pos: Vector3i, radius: int) -> Array[Actor]:
	var result: Array[Actor] = []
	for actor in actors:
		if pos.distance_to(actor.grid_pos) <= float(radius):
			result.append(actor)
	return result

func select_actor(actor: Actor) -> void:
	selected_actor = actor

func show_available_moves() -> void:
	reset_display()
	if !selected_actor:
		return

	var pos: = selected_actor.grid_pos
	if get_cell_item(pos) == INVALID_CELL_ITEM:
		push_error("selected actor is in an invalid grid position")
		return

	for cell in find_reachable_cells(pos, selected_actor.action_points):
		set_cell_item(cell, TILE_RUNTIME_VISIBLE)

func reset_display() -> void:
	for cell in get_used_cells():
		set_cell_item(cell, TILE_RUNTIME_HIDDEN)

func cell_hovered(pos: Vector3i) -> void:
	if get_cell_item(pos) == TILE_RUNTIME_VISIBLE:
		set_cell_item(pos, TILE_RUNTIME_HIGHLIGHT)

func cell_unhovered(pos: Vector3i) -> void:
	if get_cell_item(pos) == TILE_RUNTIME_HIGHLIGHT:
		set_cell_item(pos, TILE_RUNTIME_VISIBLE)

func cell_input_event(event: InputEvent, pos: Vector3i) -> void:
	if (
		get_cell_item(pos) in [TILE_RUNTIME_VISIBLE, TILE_RUNTIME_HIGHLIGHT]
		&& event is InputEventMouseButton
		&& event.button_index == MOUSE_BUTTON_RIGHT
		&& event.is_pressed()
	):
		move_ordered.emit(pos)

func find_reachable_cells(start_pos: Vector3i, max_dist: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var start: = grid_to_astar(start_pos)

	var append_if_reachable: = func(end_pos: Vector3i):
		for actor in actors:
			if actor.grid_pos == end_pos:
				return
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

func get_grid_path_to(end_pos: Vector3i) -> GridPath:
	var astar_path: = astar.get_id_path(grid_to_astar(selected_actor.grid_pos), grid_to_astar(end_pos))
	if astar_path.is_empty():
		return null

	var cost: = calc_path_cost(astar_path)

	var steps: Array[Vector3] = []
	for astar_pos in astar_path:
		steps.append(astar_to_spatial(astar_pos))

	return GridPath.new(cost, steps)

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

func astar_to_spatial(v: Vector2i) -> Vector3:
	return Vector3(float(v.x) * 0.5, 0.0, float(v.y) * 0.5)
