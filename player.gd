extends BaseUnit

# --- Player-specific state ---
var is_dragging = false
var drag_start_mouse_pos = Vector2.ZERO
var drag_start_camera_offset = Vector2.ZERO

@onready var camera = $Camera2D

#@onready var floor_layer: TileMapLayer = $"../FloorLayer"
@onready var obstacle_layer: TileMapLayer = $"../GridBase"
@onready var highlight_layer: TileMapLayer = $"../HighlightLayer"

var move_range = 5

func _ready():
	brain.register_player(self)
	update_highlights()

func _unhandled_input(event):
	if not is_my_turn or is_moving:
		return
		
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var target_grid_pos = floor_layer.local_to_map(floor_layer.to_local(mouse_pos))
		var current_grid_pos = floor_layer.local_to_map(floor_layer.to_local(global_position))
		
		if current_ap <= 0:
			print("OUT OF AP! Use End Turn button.")
			return

		var dist = get_grid_dist(current_grid_pos, target_grid_pos)
		if dist <= move_range and brain.is_tile_walkable(target_grid_pos) and not is_path_blocked(current_grid_pos, target_grid_pos):
			execute_move_command(target_grid_pos)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_start_mouse_pos = get_viewport().get_mouse_position()
				drag_start_camera_offset = camera.offset
			else:
				is_dragging = false

func execute_move_command(target_pos: Vector2i):
	move_to_grid_tile(target_pos)

func start_turn():
	super.start_turn()
	update_highlights()

func end_turn():
	is_my_turn = false
	highlight_layer.clear()
	
	#brain.end_player_turn()
	
	#brain.end_unit_turn()
	#if brain:
		#brain.end_player_turn()
	#else:
		#print("CRITICAL: GameManager node not found!")

func on_move_finished():
	update_highlights()

# --- Shared math (could later move to BaseUnit if enemies use it too) ---
func get_grid_dist(pos1: Vector2i, pos2: Vector2i) -> int:
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

func is_path_blocked(start: Vector2i, end: Vector2i) -> bool:
	var steps = get_grid_dist(start, end)
	for i in range(1, steps):
		var check_pos = Vector2(start).lerp(Vector2(end), float(i) / steps).round()
		if not brain.is_tile_walkable(Vector2i(check_pos)):
			return true
	return false

func update_highlights():
	highlight_layer.clear()
	if current_ap <= 0 or not is_my_turn:
		return
	
	var current_grid_pos = floor_layer.local_to_map(floor_layer.to_local(global_position))
	for x in range(-move_range, move_range + 1):
		for y in range(-move_range, move_range + 1):
			var target_tile = current_grid_pos + Vector2i(x, y)
			if get_grid_dist(current_grid_pos, target_tile) <= move_range:
				if brain.is_tile_walkable(target_tile) and not is_path_blocked(current_grid_pos, target_tile):
					highlight_layer.set_cell(target_tile, 1, Vector2i(0, 0))
