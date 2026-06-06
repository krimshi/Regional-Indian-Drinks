extends CanvasLayer

@onready var arrow = $Panel/Arrow
@onready var target_zone = $Panel/GreenZone
@onready var status_label = $Panel/StatusLabel
@onready var bar_background = $Panel/RedBar

var is_blending: bool = false
var arrow_speed: float = 350.0 # Speed of the arrow. Increase to make it harder!
var start_x: float = 0.0
var end_x: float = 0.0

func _ready() -> void:
	# Hide everything until the player clicks the 3D button
	hide() 
	status_label.hide()
	
	# Calculate exactly where the red bar starts and ends
	start_x = bar_background.position.x
	end_x = start_x + bar_background.size.x
	arrow.position.x = start_x

# This is called perfectly by your 3D button!
func toggle_blender(button_is_on: bool) -> void:
	if button_is_on:
		# --- START BLENDING ---
		show() 
		is_blending = true
		arrow.position.x = start_x 
		status_label.hide()
		
		# Tell the 3D juice to start spinning!
		get_tree().call_group("BlenderVisuals", "start_spinning")
	else:
		# --- STOP BLENDING ---
		is_blending = false
		_check_win_condition()

func _process(delta: float) -> void:
	if is_blending:
		# Move the arrow to the right every frame
		arrow.position.x += arrow_speed * delta
		
		# Find the exact pixel where the green zone ends
		var green_end = target_zone.position.x + target_zone.size.x
		
		# FAIL STATE: Only fail if the arrow completely passes the green zone!
		if arrow.position.x > green_end:
			_fail_game("Too long! The seeds got crushed!")

func _check_win_condition() -> void:
	var green_start = target_zone.position.x
	var green_end = target_zone.position.x + target_zone.size.x
	var arrow_center = arrow.position.x + (arrow.size.x / 2.0)
	
	# Check if the center of the arrow is inside the green block
	if arrow_center >= green_start and arrow_center <= green_end:
		_win_game()
	else:
		_fail_game("You missed the sweet spot! Bitter Juice!")

func _fail_game(reason: String) -> void:
	is_blending = false
	status_label.text = "FAILED!\n" + reason
	status_label.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
	status_label.show()
	
	get_tree().call_group("BlenderButton", "force_off")
	get_tree().call_group("BlenderVisuals", "stop_spinning")
	get_tree().call_group("BlenderVisuals", "spoil_juice")

func _win_game() -> void:
	status_label.text = "PERFECT BLEND!"
	status_label.add_theme_color_override("font_color", Color(0.1, 0.8, 0.1)) 
	status_label.show()
	
	get_tree().call_group("BlenderButton", "force_off")
	get_tree().call_group("BlenderButton", "set", "is_active", false) 
	get_tree().call_group("BlenderVisuals", "stop_spinning")
	
	# 🎯 NEW: Tell the mixer the juice is ready to be picked up!
	get_tree().call_group("BlenderVisuals", "set_blend_successful")
