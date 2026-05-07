extends Node

enum TurnState { 
	PLAYER_TURN,
	ENEMY_TURN,
	PROCESSING # Brain is busy calculating or waiting for animations
}

var turn_state: TurnState = TurnState.PROCESSING # Start in processing
#var astar_grid = AStarGrid2D.new()
var pathfinder: Pathfinder = Pathfinder.new() # Initialize pathfinder.gd
var enemies = []
var unit_positions = {} 
var enemies_finished_this_turn: int = 0
var enemy_index: int = 0 # Track which enemy is currently moving


var player
@onready var floor_layer: TileMapLayer = get_node("/root/Main/MapNodes/FloorLayer")
@onready var obstacle_layer: TileMapLayer = get_node("/root/Main/MapNodes/GridBase")
var ui_layer

var game_started = false

# --- Initialization ---

func register_player(p):
	player = p
	check_game_ready()
	
func register_ui(node):
	ui_layer = node
	check_game_ready()
	
func register_enemy(e):
	if not enemies.has(e):
		enemies.append(e)

func check_game_ready():
	if game_started: return

	if player != null and ui_layer != null:
		game_started = true
		#setup_astar()
		# Initialize the Pathfinder here
		add_child(pathfinder) 
		pathfinder.setup(floor_layer, obstacle_layer)
		print("👑 Iron Throne: Systems Online. Starting Game.")
		#print("👑 A* Grid Initialized. Region: ", astar_grid.region)
		start_player_turn()

#func setup_astar():
	#astar_grid.region = floor_layer.get_used_rect()
	#astar_grid.cell_size = Vector2(1, 1) # We use grid coordinates, not pixels
	#astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER # Keep it 4-directional
	#astar_grid.update()
	#
	## Loop through the grid and mark obstacles
	#for x in range(astar_grid.region.size.x):
		#for y in range(astar_grid.region.size.y):
			#var pos = Vector2i(x + astar_grid.region.position.x, y + astar_grid.region.position.y)
			#if not is_tile_walkable(pos):
				#astar_grid.set_point_solid(pos, true)

# --- The Flow Control (The Iron Rule) ---

## Called by any unit when they have zero AP or finish their move
func notify_unit_finished(unit):
	print("Unit finished:", unit.name, " | State:", turn_state)
	
	if turn_state == TurnState.PLAYER_TURN and unit == player:
		_transition_to_enemy_turn()
	
	elif turn_state == TurnState.ENEMY_TURN:
		if not enemies.has(unit):
			return  # Ignore weird calls (like player accidentally calling)
		enemies_finished_this_turn += 1
		enemy_index += 1 # Move the pointer to the next enemy in line
		
		# Small delay between enemies so the camera/player can breathe
		await get_tree().create_timer(0.3).timeout
		_process_next_enemy()


func _transition_to_enemy_turn():
	print("Brain: Player finished. Moving to ENEMY_TURN.")
	print("👑 Iron Throne: Commencing sequential enemy operations.")
	turn_state = TurnState.ENEMY_TURN
	enemies_finished_this_turn = 0
	enemy_index = 0 # Reset the pointer to the first enemy
	
	if enemies.size() == 0:
		start_player_turn()
		return
	
	_process_next_enemy()	
	# Start all enemies (or trigger them sequentially later)
	#for enemy in enemies:
		#enemy.start_turn()

func _process_next_enemy():
	# Check if we've reached the end of the list
	if enemy_index < enemies.size():
		var current_enemy = enemies[enemy_index]
		
		if player and player.camera:
			var tween = create_tween()
			tween.tween_property(player.camera, "global_position", current_enemy.global_position, 0.3)
		
		# Give the camera a moment to arrive before the enemy moves
		await get_tree().create_timer(0.2).timeout
		print("Brain: Commanding ", current_enemy.name)
		current_enemy.start_turn()
	else:
		# No more enemies left
		_check_enemy_queue()
				
		#print("Brain: Commanding ", current_enemy.name)
		#current_enemy.start_turn()
	#else:
		## Safety check: if index exceeds list, we must be done
		#_check_enemy_queue()

		
func _check_enemy_queue():
	if enemies_finished_this_turn >= enemies.size():
		print("Brain: All enemy operations complete.. Moving to PLAYER_TURN.")
		start_player_turn()

func start_player_turn():
	if turn_state == TurnState.PLAYER_TURN:
		return
		
	turn_state = TurnState.PLAYER_TURN
	print("▶ Player Turn")
	
	if player and player.camera:
		var tween = create_tween()
		tween.tween_property(player.camera, "global_position", player.global_position, 0.4)
	
	if player:
		player.start_turn()
	
	if ui_layer:
		ui_layer.refresh_ui()

#  Pass-through helper so Unit scripts don't break
func get_next_path_step(from_pos: Vector2i, to_pos: Vector2i) -> Vector2i:
	if pathfinder:
		return pathfinder.get_next_step(from_pos, to_pos)
	return from_pos # Fallback if pathfinder isn't ready
	
#func get_next_path_step(from_pos: Vector2i, to_pos: Vector2i) -> Vector2i:
	#update_astar_obstacles() 
	#
	## Ensure the start and end points are within the A* region
	#if not astar_grid.region.has_point(from_pos) or not astar_grid.region.has_point(to_pos):
		#print("DEBUG: Pathfinding out of bounds! From:", from_pos, " To:", to_pos)
		#return from_pos
	#
	## SURGERY: Force the player tile to be walkable for this specific calculation
	#astar_grid.set_point_solid(to_pos, false)
	#
	##var path = astar_grid.get_id_path(from_pos, to_pos)
	#var path = astar_grid.get_point_path(from_pos, to_pos)
	#
	#if path.size() > 1:
		#return path[1] 
	#
	#print("DEBUG: A* failed to find path from ", from_pos, " to ", to_pos)
	#print("From:", from_pos, " To:", to_pos)
	#print("Path:", path)
	#return from_pos

# --- Grid & Logic (Path Decoupling Source) ---

func register_unit(unit, grid_pos: Vector2i):
	unit_positions[grid_pos] = unit

func update_unit_position(old_pos: Vector2i, new_pos: Vector2i, unit):
	if unit_positions.get(old_pos) == unit:
		unit_positions.erase(old_pos)
	unit_positions[new_pos] = unit

func is_cell_occupied(grid_pos: Vector2i) -> bool:
	#return unit_positions.has(grid_pos)
	return false

# Pass-through helper so Unit scripts don't break
func is_tile_walkable(grid_coords: Vector2i) -> bool:
	if pathfinder:
		return pathfinder.is_tile_walkable(grid_coords)
	return false
	
#func is_tile_walkable(grid_coords: Vector2i) -> bool:
	## 1. Check Floor
	#var floor_data = floor_layer.get_cell_tile_data(grid_coords)
	#if floor_data == null: return false 
	#
	## 2. Check Static Obstacles
	#var obstacle_data = obstacle_layer.get_cell_tile_data(grid_coords)
	#if obstacle_data and obstacle_data.get_collision_polygons_count(0) > 0:
		#return false
		#
	## 3. Check for dynamic obstacles (Other Units)
	#if is_cell_occupied(grid_coords):
		#return false
			#
	#return true
