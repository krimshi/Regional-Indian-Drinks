extends CanvasLayer

func _ready() -> void:
	# Ensure it is visible when the game starts
	visible = true

func _unhandled_input(event: InputEvent) -> void:
	# Listen for our custom Ctrl+C shortcut
	if event.is_action_pressed("toggle_controls"):
		# Flip visibility (If true, becomes false. If false, becomes true)
		visible = !visible
