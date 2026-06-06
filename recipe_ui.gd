extends CanvasLayer

@onready var sugar_input: SpinBox = $Panel/SpinBox
@onready var add_button: Button = $Panel/Button

# 🎯 NEW: The master lock variable!
var has_completed_recipe: bool = false

func _ready() -> void:
	# Hide the menu when the game starts
	hide() 
	
	# Connect the SpinBox and Button via code so we don't have to use the Editor menu
	sugar_input.value_changed.connect(_on_sugar_amount_changed)
	add_button.pressed.connect(_on_add_button_pressed)

func show_menu() -> void:
	# 🎯 NEW: If the player already finished the recipe, completely ignore the request to open!
	if has_completed_recipe:
		return 
		
	show()
	# Free the mouse so the player can actually click the UI!
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().call_group("Player", "toggle_ui_mode", true)

func _on_sugar_amount_changed(new_value: float) -> void:
	# The magic number! If it's exactly 4, turn the button on. Otherwise, turn it off.
	if new_value == 4.0:
		add_button.disabled = false
	else:
		add_button.disabled = true

func _on_add_button_pressed() -> void:
	# 🎯 NEW: Permanently lock the UI so it can never open again!
	has_completed_recipe = true 
	
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().call_group("Player", "toggle_ui_mode", false)
	
	print("Perfect amount of sugar! Triggering Phase 3 Animation Sequence...")
	
	# Tell the Drop Zone to start the show!
	get_tree().call_group("DropZone", "start_cinematic")
