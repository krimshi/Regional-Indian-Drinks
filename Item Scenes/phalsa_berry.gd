extends RigidBody3D

@export_category("Holding Settings")
@export var hold_position: Vector3 = Vector3.ZERO
@export var hold_rotation: Vector3 = Vector3.ZERO
@export var lerp_speed: float = 15.0

@export_category("Container Settings")
@export var container_area: Area3D 

var is_held: bool = false
var camera_node: Camera3D = null
var was_held: bool = false 

@onready var pivot: Node3D = $Pivot
@onready var clump_mesh: MultiMeshInstance3D = $Pivot/Phalsa_Clump

# --- Wash Variables ---
var is_washed: bool = false
var wash_progress: float = 0.0
var required_wash_time: float = 1.5 # Takes 1.5 seconds under the tap

var contained_items: Dictionary = {}

func _physics_process(delta: float) -> void:
	if is_held and camera_node:
		if not was_held:
			was_held = true 
			_grab_contained_items()
		
		angular_velocity = Vector3.ZERO 
		
		var head_node = camera_node.get_parent()
		
		# 🎯 1. Hold Rotation Logic
		var custom_euler = Vector3(deg_to_rad(hold_rotation.x), deg_to_rad(hold_rotation.y), deg_to_rad(hold_rotation.z))
		var custom_rotation_basis = Basis.from_euler(custom_euler)
		var target_basis = (head_node.global_basis * custom_rotation_basis).orthonormalized()
		pivot.global_basis = pivot.global_basis.orthonormalized().slerp(target_basis, delta * lerp_speed)
		
		# 🎯 2. Hold Position Logic (Smoothly slide the visual mesh to your custom offset)
		pivot.position = pivot.position.lerp(hold_position, delta * lerp_speed)
		
		_update_contained_items()
	else:
		if was_held:
			was_held = false
			_release_contained_items()
			
			# 🎯 3. Save the exact physical spot AND angle the mesh is currently floating at
			var drop_transform = pivot.global_transform
			
			# 🎯 4. Instantly snap the visual Pivot folder back to zero inside the root
			pivot.transform = Transform3D.IDENTITY
			
			# 🎯 5. Paste the saved position and angle onto the physics body so it falls from the correct spot!
			global_transform = drop_transform

# --- WASHING LOGIC ---

func wash_berries() -> void:
	if is_washed:
		return
		
	# Add time based on the physics frame rate
	wash_progress += get_physics_process_delta_time()
	
	if wash_progress >= required_wash_time:
		is_washed = true
		
		# 🎯 THE FIX: Change the node's name so the Player script reads the new text!
		name = "Washed_Phalsa_Berries"
		
		_apply_clean_color()
		print("Phalsa Berries are clean and ready to blend!")

func _apply_clean_color() -> void:
	# Grab the Material Override we set up in the Inspector
	var mat = clump_mesh.material_override
	if mat:
		var tween = create_tween()
		tween.set_parallel(true) # Make the color and shine happen at the same time
		
		# Smoothly change to a deep, dark, rich Phalsa purple
		tween.tween_property(mat, "albedo_color", Color(0.527, 0.11, 0.3, 1.0), 1.0)
		
		# Drop the roughness so the berries look shiny and wet!
		tween.tween_property(mat, "roughness", 0.3, 1.0)

# --- CONTAINER LOGIC ---

func _grab_contained_items() -> void:
	contained_items.clear()
	if not container_area: 
		return 
		
	for body in container_area.get_overlapping_bodies():
		if body is RigidBody3D and body != self:
			var local_transform = pivot.global_transform.affine_inverse() * body.global_transform
			contained_items[body] = local_transform
			body.freeze = true

func _update_contained_items() -> void:
	for body in contained_items.keys():
		if is_instance_valid(body):
			var local_transform = contained_items[body]
			body.global_transform = pivot.global_transform * local_transform

func _release_contained_items() -> void:
	for body in contained_items.keys():
		if is_instance_valid(body):
			body.freeze = false 
	contained_items.clear()

# --- POURING LOGIC ---

func empty_basket() -> void:
	# Hide the 1500 berries!
	if clump_mesh:
		clump_mesh.visible = false
		
	# Change the name so the Player hover UI updates instantly
	name = "Fruit_Basket"
	print("Berries poured! The basket is now empty.")
