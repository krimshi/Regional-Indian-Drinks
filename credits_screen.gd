extends Control

func _ready() -> void:
	# Make sure the mouse is visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_back_button_pressed() -> void:
	print("Returning to Main Menu...")
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
