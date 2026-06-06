extends CanvasLayer

var is_open: bool = false

func _ready() -> void:
	visible = false

# The 3D Book will call this function!
func show_book() -> void:
	if is_open: return
	
	is_open = true
	visible = true
	
	# Free the mouse so they can click the X button, and tell the player script a UI is open
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("toggle_ui_mode"):
		player.toggle_ui_mode(true)

func hide_book() -> void:
	if not is_open: return
	
	is_open = false
	visible = false
	
	# Lock the mouse back to the game
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("toggle_ui_mode"):
		player.toggle_ui_mode(false)

# Triggered by clicking the "X" button
func _on_close_button_pressed() -> void:
	hide_book()

# Triggered by hitting the Esc key
func _unhandled_input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("ui_cancel"):
		hide_book()
		# Stop the event so the player script doesn't also try to handle Esc
		get_viewport().set_input_as_handled()
