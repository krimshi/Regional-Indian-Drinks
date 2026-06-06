extends Control

# This grabs the master audio bus so we can change the volume
@onready var bus_index = AudioServer.get_bus_index("Master")
@onready var exit_button = $BottomLayout/HBoxContainer/ExitButton

func _ready() -> void:
	# 1. Free the mouse so the player can actually click the menu!
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 2. Hide the Exit button if playing on itch.io (Web)
	if OS.has_feature("web"):
		exit_button.hide()

# --- PLAY BUTTON ---
func _on_play_button_pressed() -> void:
	print("Starting Game...")
	get_tree().change_scene_to_file("res://Scenes/kitchen.tscn")

# --- CREDITS BUTTON ---
func _on_credits_button_pressed() -> void:
	print("Opening Credits...")
	get_tree().change_scene_to_file("res://Scenes/credits_screen.tscn")

# --- EXIT BUTTON ---
func _on_exit_button_pressed() -> void:
	print("Exiting game...")
	get_tree().quit()

# --- MUSIC SLIDER ---
func _on_music_slider_value_changed(value: float) -> void:
	# Godot uses Decibels (dB), not percentages. 
	# linear_to_db perfectly converts your 0.0 - 1.0 slider into pure volume math!
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
