extends BaseUnit
class_name Enemy

func _ready():
	super()
	brain.register_enemy(self)
	print(name, " groups: ", get_groups())

func start_turn():
	super.start_turn()
	# Small delay or check can be added here if we do sequential moves later
	take_turn()

#func take_turn():
	#var player = brain.player
	#
	#if player == null or current_ap <= 0:
		#finish_action()
		#return
	#
	#var my_pos = brain.floor_layer.local_to_map(global_position)
	#var player_pos = brain.floor_layer.local_to_map(player.global_position)
	#var dist = abs(player_pos.x - my_pos.x) + abs(player_pos.y - my_pos.y)
	#
	#if dist <= attack_range:
		#attack(player)
		#return
		#
	## Calculate distance to player before deciding to move
	#var dist_to_player = abs(player_pos.x - my_pos.x) + abs(player_pos.y - my_pos.y)
	#
	## If distance is 1, we are already adjacent. Stop here.
	#if dist_to_player <= 1:
		#print(name, ": Already adjacent to player. Preparing to attack.")
		## Trigger Attack Animation here later
		#finish_action()
		#return
	## Ask the Brain for the A* verified next step
	#var target = brain.get_next_path_step(my_pos, player_pos)
	#
	## If the target is the player's actual tile, we don't want to step ON them
	#if target == player_pos:
		#print(name, ": Next step is player tile. Staying put to attack.")
		#finish_action()
		#return
#
	#if target != my_pos and brain.is_tile_walkable(target):
		#move_to_grid_tile(target)
	#else:
		#print(name, ": No valid path step found.")
		#finish_action()

func take_turn():
	var player = brain.player
	
	if brain.player == null or not is_instance_valid(brain.player):
		print("🛡️ [AI] No player detected. Standing down.")
		finish_action()
		return
		
	if player == null or current_ap <= 0:
		finish_action()
		return
	
	var my_pos = brain.floor_layer.local_to_map(global_position)
	var player_pos = brain.floor_layer.local_to_map(player.global_position)
	var dist = abs(player_pos.x - my_pos.x) + abs(player_pos.y - my_pos.y)
	
	# 1. Check if we can attack right now
	if dist <= attack_range:
		print(name, ": In range! Attacking.")
		attack(player)
		return
		
	# 2. If not in range, find the next step toward the player
	var target = brain.get_next_path_step(my_pos, player_pos)
	
	# 3. Safety: Don't step on the player
	if target == player_pos:
		print(name, ": Path wants to step on player. Waiting.")
		finish_action()
		return

	# 4. Move if the tile is valid
	if target != my_pos and brain.is_tile_walkable(target):
		move_to_grid_tile(target)
	else:
		print(name, ": Path blocked or no path found.")
		finish_action()

func attack(target: BaseUnit):
	print("⚔️ [ACTION] ", name, " is performing an attack on ", target.name)
	print("   Current AP: ", current_ap, " | Damage Output: ", attack_damage)
	
	#print(name, " hits for ", attack_damage)
	target.take_damage(attack_damage)
	# IMPORTANT: Ensure AP is spent so they don't loop-attack!
	current_ap -= 1
	
	finish_action()

func on_move_finished():
	# If we have more AP, we could call take_turn() again for multi-step AI
	# For now, we finish after one step
	if not check_ap_and_finish():
		take_turn()
	else:
		finish_action()
	finish_action()

## Helper to ensure we follow the Iron Rule
func finish_action():
	current_ap = 0
	is_my_turn = false
	check_ap_and_finish()
