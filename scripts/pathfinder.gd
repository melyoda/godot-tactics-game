extends Node
class_name Pathfinder

var astar_grid = AStarGrid2D.new()

var floor_layer: TileMapLayer
var obstacle_layer: TileMapLayer
var brain # reference to GameManager (for unit checks)

# --- Setup ---

func setup(floor, obstacle, game_brain):
	floor_layer = floor
	obstacle_layer = obstacle
	brain = game_brain
	
	astar_grid.region = floor_layer.get_used_rect()
	astar_grid.cell_size = Vector2(1, 1)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	# Initialize grid
	for x in range(astar_grid.region.size.x):
		for y in range(astar_grid.region.size.y):
			var pos = Vector2i(
				x + astar_grid.region.position.x,
				y + astar_grid.region.position.y
			)
			if not is_tile_walkable(pos):
				astar_grid.set_point_solid(pos, true)

# --- Pathfinding ---

func get_next_step(from_pos: Vector2i, to_pos: Vector2i) -> Vector2i:
	update_obstacles()
	
	if not astar_grid.region.has_point(from_pos) or not astar_grid.region.has_point(to_pos):
		print("DEBUG: Pathfinding out of bounds!", from_pos, to_pos)
		return from_pos
	
	# Allow pathing TO player
	astar_grid.set_point_solid(to_pos, false)
	
	var path = astar_grid.get_point_path(from_pos, to_pos)
	
	if path.size() > 1:
		return path[1]
	
	print("DEBUG: A* failed", from_pos, to_pos)
	print("Path:", path)
	return from_pos

func update_obstacles():
	var region = astar_grid.region
	
	for x in range(region.position.x, region.end.x):
		for y in range(region.position.y, region.end.y):
			var pos = Vector2i(x, y)
			astar_grid.set_point_solid(pos, not is_tile_walkable(pos))

# --- Tile Logic ---

func is_tile_walkable(grid_coords: Vector2i) -> bool:
	var floor_data = floor_layer.get_cell_tile_data(grid_coords)
	if floor_data == null:
		return false 
	
	var obstacle_data = obstacle_layer.get_cell_tile_data(grid_coords)
	if obstacle_data and obstacle_data.get_collision_polygons_count(0) > 0:
		return false
		
	# IMPORTANT: still uses GameManager for unit blocking
	if brain.is_cell_occupied(grid_coords):
		return false
			
	return true
