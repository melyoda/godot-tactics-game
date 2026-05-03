extends Node

enum TurnState { 
	PLAYER_TURN,
	ENEMY_TURN,
	PROCESSING
}
#var current_state = TurnState.PLAYER_TURN
var turn_state: TurnState
var enemies = []
var unit_positions = {} # Key: Vector2i, Value: Node (the unit)

var player
@onready var floor_layer: TileMapLayer = get_node("/root/Main/MapNodes/FloorLayer")
@onready var obstacle_layer: TileMapLayer = get_node("/root/Main/MapNodes/GridBase")
var ui_layer

var game_started = false

func register_player(p):
	player = p
	print("Player registered:", p)
	check_game_ready()
	
func register_ui(node):
	ui_layer = node
	print("UI registered:", node)
	check_game_ready()
	
func register_enemy(e):
	enemies.append(e)
	print("Enemies registered:", e)
	
#func register_floor(layer):
	#floor_layer = layer
	#print("layer registered:", layer)
#
#func register_obstacles(layer):
	#obstacle_layer = layer
	#print("Obstecal layer registered:", layer)


func check_game_ready():
	if game_started:
		return

	if player != null and ui_layer != null:
		game_started = true
		print("Game is ready → starting first turn")
		start_player_turn()

func _ready():
	# Wait until the very end of the first frame
	# This ensures Player, TileMaps, and UI are all fully initialized
	await get_tree().process_frame 


func end_player_turn():
	#current_state = TurnState.ENEMY_TURN
	print("Brain: Player turn ended. Starting Enemy simulation...")
	
	#start_enemy_turns()
	
	# The Enemy turn here instead of in the player
	#current_state = TurnState.ENEMY_TURN
	turn_state = TurnState.ENEMY_TURN
	print("▶ Enemy Turn")

	for enemy in enemies:
		enemy.start_turn()
	#var timer = get_tree().create_timer(2.0)
	#timer.timeout.connect(start_player_turn)
	
func end_enemy_turn():
	print("Brain: Player turn starting again")
	start_player_turn()


func start_player_turn():
	#print("START TURN CALLED FROM:", get_stack())
	if player == null:
		push_error("Player not registered!")
		return
		
	if turn_state == TurnState.PLAYER_TURN:
		return
		
	#current_state = TurnState.PLAYER_TURN
	turn_state = TurnState.PLAYER_TURN
	print("▶ Player Turn")
	print("Brain: Starting Player turn.")
	
	# Tell the player to reset its AP
	player.start_turn()
	
	# Tell the UI to enable the button
	if ui_layer:
		ui_layer.refresh_ui()

func start_enemy_turns():
	if turn_state == TurnState.ENEMY_TURN:
		return
		
	for enemy in enemies:
		enemy.start_turn()


#func end_unit_turn():
	#if turn_state == TurnState.PLAYER_TURN:
		#start_enemy_turns()
	#
	#elif turn_state == TurnState.ENEMY_TURN:
		## when enemies finish one by one later
		#start_player_turn()

func register_unit(unit, grid_pos: Vector2i):
	unit_positions[grid_pos] = unit

func update_unit_position(old_pos: Vector2i, new_pos: Vector2i, unit):
	unit_positions.erase(old_pos)
	unit_positions[new_pos] = unit

func is_cell_occupied(grid_pos: Vector2i) -> bool:
	return unit_positions.has(grid_pos)

	# Walking rules 
func is_tile_walkable(grid_coords: Vector2i) -> bool:
	# 1. Check if the tile exists (Floor)
	var floor_data = floor_layer.get_cell_tile_data(grid_coords)
	if floor_data == null: return false 
	
	# 2. Check for static obstacles (Walls)
	var obstacle_data = obstacle_layer.get_cell_tile_data(grid_coords)
	if obstacle_data and obstacle_data.get_collision_polygons_count(0) > 0:
		return false
		
	# 3. Check for dynamic obstacles (Other Units)
	if unit_positions.has(grid_coords):
		return false
			
	return true
