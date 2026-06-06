extends AnimatableBody3D

@export_category("Movement Settings")
@export var open_distance: float = 0.8
@export var slide_speed: float = 0.4
@export var slide_axis: Vector3 = Vector3(0, 0, 1)
@export var auto_close_distance: float = 2.0

var is_open: bool = false
var is_moving: bool = false
var tween: Tween
var player_ref: CharacterBody3D = null
var items_inside: Array[RigidBody3D] = []
var _last_drawer_global_pos: Vector3 = Vector3.ZERO

@onready var start_position: Vector3 = position

func _process(_delta: float) -> void:
	if is_open and is_instance_valid(player_ref) and not is_moving:
		var current_distance = global_position.distance_to(player_ref.global_position)
		if current_distance > auto_close_distance:
			close_drawer()

func interact(player_node: CharacterBody3D) -> void:
	# Don't let the player spam click while it's actively sliding
	if is_moving: return
	
	player_ref = player_node
	if is_open:
		close_drawer()
	else:
		open_drawer()

func open_drawer() -> void:
	is_open = true
	_animate_slide(start_position + (slide_axis * open_distance))

func close_drawer() -> void:
	is_open = false
	_animate_slide(start_position)

func _animate_slide(target_pos: Vector3) -> void:
	is_moving = true
	
	if tween and tween.is_running():
		tween.kill()
		
	# Freeze all items right before moving
	for item in items_inside:
		if is_instance_valid(item):
			item.set_deferred("freeze", true)
			
	var start_pos = position
	# Use the class-level variable here so the lambda function can update it safely!
	_last_drawer_global_pos = global_position
	
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	tween.tween_method(func(weight: float):
		# 1. Update the drawer's position locally
		position = start_pos.lerp(target_pos, weight)
		
		# 2. Calculate frame-by-frame global displacement
		var current_drawer_global_pos := global_position
		var frame_displacement := current_drawer_global_pos - _last_drawer_global_pos
		
		# 3. Drag items along frame-by-frame
		for item in items_inside:
			if is_instance_valid(item):
				item.global_position += frame_displacement
				
		_last_drawer_global_pos = current_drawer_global_pos
	, 0.0, 1.0, slide_speed)

	tween.finished.connect(_on_slide_finished)

func _on_slide_finished() -> void:
	is_moving = false
	
	# Safely unfreeze items so they settle naturally inside the drawer boundaries
	for item in items_inside:
		if is_instance_valid(item):
			item.set_deferred("freeze", false)


# Add this to the bottom of your drawer script
func force_close() -> void:
	# If it's already closed and not moving, do nothing
	if not is_open and not is_moving: 
		return
		
	is_open = false
	player_ref = null # Clear player reference
	
	# Override and animate straight back to the starting position
	_animate_slide(start_position)


func _on_item_detector_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and body != self:
		if not items_inside.has(body):
			items_inside.append(body)

func _on_item_detector_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		# MAGIC FIX 2: Sensor Lock!
		# If the drawer is actively moving, Godot's Area3D might glitch and 
		# accidentally think the item fell out. We force it to ignore exits while moving!
		if is_moving:
			return
			
		if items_inside.has(body):
			items_inside.erase(body)
