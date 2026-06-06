extends CanvasLayer

func _ready() -> void:
	# Make sure it's always visible when the level starts
	visible = true

func _on_restart_button_pressed() -> void:
	print("Quick Restart clicked! Reloading kitchen...")
	
	# Unpause the engine just in case the player clicks this while the Win Screen is open
	get_tree().paused = false 
	
	# Instantly deletes and rebuilds the current scene
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	print("Main Menu clicked! Returning to menu...")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
