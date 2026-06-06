extends CanvasLayer

func _ready() -> void:
	# Hide the screen when the game starts
	visible = false

# The Glass will call this function!
func show_win_screen() -> void:
	visible = true
	
	# 1. Free the mouse pointer so the player can actually click the buttons!
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 2. Pause the entire 3D game in the background
	get_tree().paused = true

func _on_replay_button_pressed() -> void:
	print("Replay clicked! Restarting kitchen...")
	
	# Unpause the game engine BEFORE restarting, otherwise it stays frozen!
	get_tree().paused = false
	
	# Instantly deletes the current scene and reloads it fresh
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	print("Main Menu clicked! Returning to menu...")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
