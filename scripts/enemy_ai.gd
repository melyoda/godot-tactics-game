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
	
	# NEW: Calculate distance to player before deciding to move
	var dist_to_player = abs(player_pos.x - my_pos.x) + abs(player_pos.y - my_pos.y)
	
	# If distance is 1, we are already adjacent. Stop here.
	if dist_to_player <= 1:
		print(name, ": Already adjacent to player. Preparing to attack.")
		# Trigger Attack Animation here later
		finish_action()
		return
	
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
		
	# 3. Final Surgical Gate (Walkable? Occupied?)
	# This single check handles walls, other enemies, and the player space.
	if brain.is_tile_walkable(target):
		move_to_grid_tile(target)
	else:
		#print(name, ": Path blocked or target occupied. Waiting.")
		print(name, ": Path blocked by obstacle. Ending turn.")
		finish_action()
		
	## 2. SURGICAL CHECK: Is the player (or anyone else) on my target tile?
	if target == player_pos:
		print(name, ": Player is in my way! Staying put to attack/wait.")
		# Here you would trigger an attack animation
		finish_action() 
		return

func on_move_finished():
	# If we have more AP, we could call take_turn() again for multi-step AI
	# For now, we finish after one step
	finish_action()

## Helper to ensure we follow the Iron Rule
func finish_action():
	current_ap = 0
	is_my_turn = false
	check_ap_and_finish()
