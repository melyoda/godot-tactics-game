extends CanvasLayer

# Connect the button here in the inspector or via code
@onready var player = GameManager.player
@onready var button = $Control/Button

func _ready():
	GameManager.register_ui(self)
	await get_tree().process_frame
	player = GameManager.player
	# Linking the button signal to this script
	if not button.pressed.is_connected(_on_end_turn_pressed):
			button.pressed.connect(_on_end_turn_pressed)

func _on_end_turn_pressed():
	#if player.current_state == player.TurnState.MY_TURN:
	if player.is_my_turn:
		player.end_turn()
		button.disabled = true
		button.text = "Waiting..."

# The player will call this when start_turn() runs
func refresh_ui():
	button.disabled = false
	button.text = "End Turn"
