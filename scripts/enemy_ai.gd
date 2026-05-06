extends BaseUnit
class_name Enemy

func _ready():
	brain.register_enemy(self)

func start_turn():
	super.start_turn()
	# Small delay or check can be added here if we do sequential moves later
	take_turn()

func take_turn():
	var player = brain.player
	
	if player == null or current_ap <= 0:
		finish_action()
		return
	
	var my_pos = brain.floor_layer.local_to_map(global_position)
	var player_pos = brain.floor_layer.local_to_map(player.global_position)
	
	# 1. Check distance
	var dist_to_player = abs(player_pos.x - my_pos.x) + abs(player_pos.y - my_pos.y)
	
	if dist_to_player <= 1:
		print(name, ": Already adjacent to player. Preparing to attack.")
		# Combat logic will go here
		finish_action()
		return

	# 2. Get the A* step
	var target = brain.get_next_path_step(my_pos, player_pos)
	
	# 3. Movement Logic
	if target == player_pos:
		print(name, ": Next step is player tile. Staying put to attack.")
		finish_action()
		return # Stop here!

	if target != my_pos and brain.is_tile_walkable(target):
		move_to_grid_tile(target)
	else:
		print(name, ": No valid path step found.")
		finish_action()

func on_move_finished():
	# If we have more AP, we could call take_turn() again for multi-step AI
	# For now, we finish after one step
	finish_action()

## Helper to ensure we follow the Iron Rule
func finish_action():
	current_ap = 0
	is_my_turn = false
	check_ap_and_finish()
