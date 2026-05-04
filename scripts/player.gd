extends BaseUnit

# --- Player-specific state ---
var is_dragging = false
var drag_start_mouse_pos = Vector2.ZERO
var drag_start_camera_offset = Vector2.ZERO

@onready var camera = $Camera2D
# Note: floor_layer is now accessed via brain.floor_layer
@onready var highlight_layer: TileMapLayer = get_node("/root/Main/MapNodes/HighlightLayer")

var move_range = 5

func _ready():
	brain.register_player(self)
	# Wait a frame to ensure Brain has layers ready before highlighting
	await get_tree().process_frame
	update_highlights()

func _unhandled_input(event):
	# The Iron Rule: No input if it's not our turn or we are mid-animation
	if not is_my_turn or is_moving or brain.turn_state != brain.TurnState.PLAYER_TURN:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		# Use Brain as the source for coordinate conversion
		var target_grid_pos = brain.floor_layer.local_to_map(brain.floor_layer.to_local(mouse_pos))
		var current_grid_pos = brain.floor_layer.local_to_map(brain.floor_layer.to_local(global_position))
		
		if current_ap <= 0:
			return

		var dist = get_grid_dist(current_grid_pos, target_grid_pos)
		
		# Check movement validity through the Brain's eyes
		if dist <= move_range and brain.is_tile_walkable(target_grid_pos) and not is_path_blocked(current_grid_pos, target_grid_pos):
			move_to_grid_tile(target_grid_pos)

	# Camera Dragging logic remains the same
	handle_camera_drag(event)

func handle_camera_drag(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			is_dragging = true
			drag_start_mouse_pos = get_viewport().get_mouse_position()
			drag_start_camera_offset = camera.offset
		else:
			is_dragging = false
	
	if event is InputEventMouseMotion and is_dragging:
		var move_vec = get_viewport().get_mouse_position() - drag_start_mouse_pos
		camera.offset = drag_start_camera_offset - move_vec

func start_turn():
	super.start_turn() # Resets AP and sets is_my_turn = true
	update_highlights()

## Manual End Turn (usually from a UI button)
func end_turn():
	if not is_my_turn: return
	
	current_ap = 0 # Drain AP to trigger the finish logic
	highlight_layer.clear()
	check_ap_and_finish() # This tells the Brain we are done

func on_move_finished():
	# Update visuals after every step
	update_highlights()

# --- Helpers using Brain's logic ---

func get_grid_dist(pos1: Vector2i, pos2: Vector2i) -> int:
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

func is_path_blocked(start: Vector2i, end: Vector2i) -> bool:
	var steps = get_grid_dist(start, end)
	if steps <= 1: return false
	
	for i in range(1, steps):
		var check_pos = Vector2(start).lerp(Vector2(end), float(i) / steps).round()
		if not brain.is_tile_walkable(Vector2i(check_pos)):
			return true
	return false

func update_highlights():
	highlight_layer.clear()
	if current_ap <= 0 or not is_my_turn:
		return
	
	var current_grid_pos = brain.floor_layer.local_to_map(brain.floor_layer.to_local(global_position))
	for x in range(-move_range, move_range + 1):
		for y in range(-move_range, move_range + 1):
			var target_tile = current_grid_pos + Vector2i(x, y)
			if get_grid_dist(current_grid_pos, target_tile) <= move_range:
				if brain.is_tile_walkable(target_tile) and not is_path_blocked(current_grid_pos, target_tile):
					highlight_layer.set_cell(target_tile, 1, Vector2i(0, 0))
