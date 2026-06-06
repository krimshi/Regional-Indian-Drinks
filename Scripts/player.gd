extends CharacterBody3D

@export_category("Movement")
const WALK_SPEED = 4.0
const CROUCH_SPEED = 2.0
const MOUSE_SENSITIVITY = 0.002

@export_category("Physics Grabbing")
const PULL_POWER = 8

@export_category("Crouching")
const CROUCH_DEPTH = -0.6  # Adjust this to change how low you duck
const CROUCH_SMOOTHNESS = 8.0 # Adjust this to change how fast you crouch/stand

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/InteractionRay
@onready var hold_point: Marker3D = $Head/Camera3D/HoldPoint

# 🎯 NEW: Added the UI Label reference here
@onready var hover_text: Label = $CanvasLayer/HoverText

var grabbed_object: RigidBody3D = null
var default_head_y: float = 0.0
var is_ui_open: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Lock in exactly where the camera starts so we always return to the right height
	default_head_y = head.position.y 

func _input(event: InputEvent) -> void:
	if is_ui_open:
		return
	# 1. Camera Look Logic
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			return
		head.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))
		
	# 2. Mouse Wheel Logic for pushing/pulling items
	if event is InputEventMouseButton and event.is_pressed():
		# Only allow scrolling if we are actually holding something
		if grabbed_object:
			var scroll_speed = 0.1
			
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				# Push away (more negative Z)
				hold_point.position.z -= scroll_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				# Pull closer (less negative Z)
				hold_point.position.z += scroll_speed
				
			# THE LIMIT: Clamp the Z position so it can't go out of bounds!
			# Note: -1.5 is the minimum (furthest away), -0.6 is the maximum (closest)
			hold_point.position.z = clamp(hold_point.position.z, -1.5, -0.6)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta: float) -> void:
	if is_ui_open:
		return
	# 🎯 NEW: Run the hover text check every single frame
	_update_hover_text()
	
	if Input.is_action_just_pressed("mouse_click_left") and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return

	# LEFT CLICK: Pick up objects
	if Input.is_action_just_pressed("mouse_click_left"):
		_try_grab_object()
				
	if Input.is_action_just_released("mouse_click_left"):
		_release_object()

	# RIGHT CLICK: Interact with drawers, doors, and objects
	if Input.is_action_just_pressed("mouse_click_right"):
		if raycast.is_colliding():
			var target = raycast.get_collider()
			if target.has_method("interact"):
				target.interact(self)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Determine current speed and target head height based on input
	var current_speed = WALK_SPEED
	var target_head_y = default_head_y
	
	if Input.is_action_pressed("crouch"):
		current_speed = CROUCH_SPEED
		target_head_y = default_head_y + CROUCH_DEPTH
		
	# Smoothly animate the head moving up and down
	head.position.y = lerp(head.position.y, target_head_y, delta * CROUCH_SMOOTHNESS)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (head.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		# Apply the dynamic current_speed instead of the hardcoded const
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
	
	if grabbed_object:
		_maintain_grab_physics()

func _try_grab_object() -> void:
	if raycast.is_colliding():
		var target = raycast.get_collider()
		
		# 🏆 THE SURGICAL WIN HACK: Check it directly from the player's eyes!
		if target is RigidBody3D and target.name.to_lower().contains("glass"):
			var state = target.find_child("State", true, false)
			if state and state.visible:
				print("Player grabbed the winning glass!")
				get_tree().call_group("WinScreen", "show_win_screen")
				return # Stop the script here so they don't awkwardly hold it on the menu screen
		
		if target is RigidBody3D:
			grabbed_object = target
			grabbed_object.gravity_scale = 0.0
			grabbed_object.sleeping = false
			grabbed_object.continuous_cd = true
			
			# 🎯 Tell the RayCast to ignore the item we are holding!
			raycast.add_exception(grabbed_object)
			
			# Tell the item it is being held and give it the camera for reference
			if "is_held" in grabbed_object:
				grabbed_object.is_held = true
				grabbed_object.camera_node = camera
				
			# 🎯 FIX: Added the missing line to tell the Drop Zone what we picked up!
			get_tree().call_group("DropZone", "check_player_hands", grabbed_object.name)

func _release_object() -> void:
	if grabbed_object:
		grabbed_object.remove_collision_exception_with(self)
		grabbed_object.gravity_scale = 1.0
		grabbed_object.linear_velocity = Vector3.ZERO
		grabbed_object.angular_velocity = Vector3.ZERO
		
		# 🎯 Tell the RayCast it can hit this item again!
		raycast.remove_exception(grabbed_object)
		
		# Tell the item it was dropped so real physics can take over again
		if "is_held" in grabbed_object:
			grabbed_object.is_held = false
			
		# 🎯 Tell the Drop Zone our hands are empty!
		get_tree().call_group("DropZone", "check_player_hands", "")
		
		# 🎯 FIX: Set this to null exactly ONCE at the very end!
		grabbed_object = null

func _maintain_grab_physics() -> void:
	if not is_instance_valid(grabbed_object):
		grabbed_object = null
		return
		
	var target_pos = hold_point.global_position
	var current_pos = grabbed_object.global_position
	var distance_vector = target_pos - current_pos
	var distance = distance_vector.length()
	
	if distance > 1.5:
		_release_object()
		return

	if grabbed_object.get_contact_count() > 0:
		for body in grabbed_object.get_colliding_bodies():
			if body is AnimatableBody3D or body.name.contains("Door"):
				grabbed_object.linear_velocity = Vector3.ZERO
				_release_object()
				return
	
	var target_velocity = distance_vector * PULL_POWER
	if target_velocity.length() > 20.0:
		target_velocity = target_velocity.limit_length(20.0)
		
	grabbed_object.linear_velocity = target_velocity
	grabbed_object.angular_velocity *= 0.85

func _update_hover_text() -> void:
	if grabbed_object:
		hover_text.text = ""
		return

	if raycast.is_colliding():
		var target = raycast.get_collider()
		
		# 🎯 THE NEW SAFETY CHECK: If the object was just deleted, stop right here!
		if not is_instance_valid(target):
			hover_text.text = ""
			return
		
		# 🎯 THE ORIGINAL FIX: Only reads nodes that have your pickable item script!
		if "is_held" in target:
			
			var formatted_name = str(target.name).replace("_", " ")
			hover_text.text = formatted_name
			
		else:
			hover_text.text = ""
	else:
		hover_text.text = ""

# The UI will call this to freeze/unfreeze the player's controls
func toggle_ui_mode(state: bool) -> void:
	is_ui_open = state
