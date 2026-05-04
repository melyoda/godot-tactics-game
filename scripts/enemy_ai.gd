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
	
	var target = my_pos
	
	# 1. Calculate the step toward the player
	if player_pos.x > my_pos.x:
		target.x += 1
	elif player_pos.x < my_pos.x:
		target.x -= 1
	elif player_pos.y > my_pos.y:
		target.y += 1
	elif player_pos.y < my_pos.y:
		target.y -= 1
	
	# 2. SURGICAL CHECK: Is the player (or anyone else) on my target tile?
	if target == player_pos:
		print(name, ": Player is in my way! Staying put to attack/wait.")
		# Here you would trigger an attack animation
		finish_action() 
		return

	# 3. Check if the tile is actually walkable (walls/obstacles)
	if brain.is_tile_walkable(target):
		move_to_grid_tile(target)
	else:
		print(name, ": Path blocked by obstacle. Ending turn.")
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
