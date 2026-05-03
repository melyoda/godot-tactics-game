extends CharacterBody2D
class_name BaseUnit  # This allows other scripts to "extend" this one

@export var max_ap: int = 2
var current_ap: int = 0
var is_my_turn: bool = false
var is_moving: bool = false

@onready var brain = GameManager #get_node("/root/Main/GameManager") 
@onready var floor_layer = get_node("/root/Main/MapNodes/FloorLayer")

func start_turn():
	current_ap = max_ap
	is_my_turn = true

func move_to_grid_tile(target_grid_pos: Vector2i):
	is_moving = true
	current_ap -= 1
	
	var old_grid_pos = floor_layer.local_to_map(global_position)
	var target_world_pos = floor_layer.map_to_local(target_grid_pos)
	
	# Update the Brain's dictionary so this tile is now "Occupied"
	brain.update_unit_position(old_grid_pos, target_grid_pos, self)
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_world_pos, 0.4).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(func(): 
		is_moving = false
		on_move_finished()
	)

func on_move_finished():
	# This will be overridden by Player/Enemy if they need to do something specific
	pass
