extends BaseUnit
class_name Enemy

func _ready():
	brain.register_enemy(self)
	
func start_turn():
	super.start_turn()
	take_turn()

func take_turn():
	var player = GameManager.player
	
	if player == null:
		end_turn()
		return
	
	var my_pos = floor_layer.local_to_map(global_position)
	var player_pos = floor_layer.local_to_map(player.global_position)
	
	var target = my_pos
	
	# simple step toward player
	if player_pos.x > my_pos.x:
		target.x += 1
	elif player_pos.x < my_pos.x:
		target.x -= 1
	elif player_pos.y > my_pos.y:
		target.y += 1
	elif player_pos.y < my_pos.y:
		target.y -= 1
	
	if brain.is_tile_walkable(target):
		move_to_grid_tile(target)
	else:
		end_turn()

func on_move_finished():
# After moving, the enemy ends its turn
	end_turn()

func end_turn():
	is_my_turn = false
	
	#brain.end_enemy_turn()
	#brain.end_unit_turn()
	#GameManager.end_enemy_turn()
