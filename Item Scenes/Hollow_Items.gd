extends RigidBody3D

@export_category("Holding Orientation")
@export var hold_rotation: Vector3 = Vector3.ZERO
@export var rotation_speed: float = 15.0

@export_category("Container Settings")
@export var container_area: Area3D # Assign your Area3D here in the Inspector!

var is_held: bool = false
var camera_node: Camera3D = null
var was_held: bool = false 

@onready var pivot: Node3D = $Pivot

# A dictionary to remember exactly where the items were sitting inside the bowl
var contained_items: Dictionary = {}

func _physics_process(delta: float) -> void:
	if is_held and camera_node:
		
		# 🎯 TRIGGER: The exact frame we pick the bowl up
		if not was_held:
			was_held = true 
			_grab_contained_items()
		
		# Stop physical tumbling while held
		angular_velocity = Vector3.ZERO 
		
		# Get the Player's body node (handles left/right rotation only)
		var head_node = camera_node.get_parent()
		
		# Convert your Inspector degrees into Godot math
		var custom_euler = Vector3(
			deg_to_rad(hold_rotation.x), 
			deg_to_rad(hold_rotation.y), 
			deg_to_rad(hold_rotation.z)
		)
		var custom_rotation_basis = Basis.from_euler(custom_euler)
		
		# Calculate perfect target angle and clean the math (orthonormalized)
		var target_basis = (head_node.global_basis * custom_rotation_basis).orthonormalized()
		
		# Smoothly rotate the visual folder
		pivot.global_basis = pivot.global_basis.orthonormalized().slerp(target_basis, delta * rotation_speed)
		
		# 🎯 CONSTANT UPDATE: Keep the apples glued to the moving pivot
		_update_contained_items()
		
	else:
		# 🎯 TRIGGER: The exact frame we drop the bowl
		if was_held:
			was_held = false
			_release_contained_items()
			
			# 1. Save the exact angle the item is facing on your screen
			var drop_basis = pivot.global_basis.orthonormalized()
			
			# 2. Instantly reset the visual folder back to zero
			pivot.transform.basis = Basis.IDENTITY
			
			# 3. Paste the saved angle onto the root physics body!
			global_basis = drop_basis

# --- CONTAINER LOGIC ---

func _grab_contained_items() -> void:
	contained_items.clear()
	
	if not container_area: 
		return # Skip if this isn't a container object
		
	# Check everything touching the inside of the bowl
	for body in container_area.get_overlapping_bodies():
		if body is RigidBody3D and body != self:
			
			# Save the item's exact position relative to the bowl's visual Pivot
			var local_transform = pivot.global_transform.affine_inverse() * body.global_transform
			contained_items[body] = local_transform
			
			# Completely freeze the physics engine for this item!
			body.freeze = true

func _update_contained_items() -> void:
	for body in contained_items.keys():
		if is_instance_valid(body):
			var local_transform = contained_items[body]
			
			# Force the item to perfectly follow the bowl's new position and rotation
			body.global_transform = pivot.global_transform * local_transform

func _release_contained_items() -> void:
	for body in contained_items.keys():
		if is_instance_valid(body):
			# Unfreeze it so gravity takes over again!
			body.freeze = false 
			
	contained_items.clear()
