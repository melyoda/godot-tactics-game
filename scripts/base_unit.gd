extends CharacterBody2D
class_name BaseUnit

@export var max_ap: int = 2
var current_ap: int = 0
var is_my_turn: bool = false
var is_moving: bool = false
var has_notified_brain: bool = false

# The Brain is the single source of truth
@onready var brain = GameManager 

func start_turn():
	current_ap = max_ap
	is_my_turn = true
	has_notified_brain = false # Reset the gate!
	print(name, " turn started. AP: ", current_ap)

func move_to_grid_tile(target_grid_pos: Vector2i):
	if current_ap <= 0:
		return
		
	is_moving = true
	current_ap -= 1
	
	# Ask Brain for coordinate conversions instead of holding TileMap references here
	var old_grid_pos = brain.floor_layer.local_to_map(global_position)
	var target_world_pos = brain.floor_layer.map_to_local(target_grid_pos)
	
	# Update the Brain's occupation map
	brain.update_unit_position(old_grid_pos, target_grid_pos, self)
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_world_pos, 0.3).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(_on_tween_finished)

func _on_tween_finished():
	is_moving = false
	on_move_finished()
	check_ap_and_finish()

func on_move_finished():
	# Overridden by Player/Enemy for specific logic (like triggering combat)
	pass

## The Iron Rule: Tell the Brain when we are spent
func check_ap_and_finish():
	if current_ap <= 0 and not has_notified_brain:
		has_notified_brain = true # Close the gate!
		is_my_turn = false
		print("DEBUG: ", name, " is out of AP. Notifying Brain.")
		brain.notify_unit_finished(self)
