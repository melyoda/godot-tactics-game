extends Node
class_name Pathfinder

var astar_grid = AStarGrid2D.new()

# We need references to the layers to check walkability
var floor_layer: TileMapLayer
var obstacle_layer: TileMapLayer

func setup(floor_node: TileMapLayer, obstacle_node: TileMapLayer):
	floor_layer = floor_node
	obstacle_layer = obstacle_node
	
	astar_grid.region = floor_layer.get_used_rect()
	astar_grid.cell_size = Vector2(1, 1)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	update_grid_obstructions()

func update_grid_obstructions():
	var region = astar_grid.region
	for x in range(region.position.x, region.end.x):
		for y in range(region.position.y, region.end.y):
			var pos = Vector2i(x, y)
			astar_grid.set_point_solid(pos, not is_tile_walkable(pos))

func is_tile_walkable(grid_coords: Vector2i) -> bool:
	# 1. Check Floor exists
	var floor_data = floor_layer.get_cell_tile_data(grid_coords)
	if floor_data == null: return false 
	
	# 2. Check Static Obstacles (Walls/GridBase)
	var obstacle_data = obstacle_layer.get_cell_tile_data(grid_coords)
	if obstacle_data and obstacle_data.get_collision_polygons_count(0) > 0:
		return false
			
	return true

func get_next_step(from_pos: Vector2i, to_pos: Vector2i) -> Vector2i:
	# Refresh obstacles in case units moved (or just for safety)
	update_grid_obstructions() 
	
	if not astar_grid.region.has_point(from_pos) or not astar_grid.region.has_point(to_pos):
		return from_pos
	
	# Temporary "Surgery": make the target walkable (e.g., the player's tile)
	# so A* can calculate a path TO the tile, even if someone is on it.
	var was_solid = astar_grid.is_point_solid(to_pos)
	astar_grid.set_point_solid(to_pos, false)
	
	var path = astar_grid.get_point_path(from_pos, to_pos)
	
	# Restore the solid state
	astar_grid.set_point_solid(to_pos, was_solid)
	
	if path.size() > 1:
		return path[1] 
	
	return from_pos
