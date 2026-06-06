extends RigidBody3D

@export_category("Holding Settings")
@export var hold_position: Vector3 = Vector3.ZERO
@export var hold_rotation: Vector3 = Vector3.ZERO
@export var lerp_speed: float = 15.0

@export_category("Water Settings")
@export var water_pivot: Node3D
@export var spout: Marker3D
var water_amount: float = 1.0 # 1.0 is full, 0.0 is empty
var pour_speed: float = 0.5   # Takes 2 seconds to empty

var is_held: bool = false
var camera_node: Camera3D = null
var was_held: bool = false 

# 🎯 The script will now easily find this since you added it to the tree!
@onready var pivot: Node3D = $Pivot

func _physics_process(delta: float) -> void:
	if is_held and camera_node:
		if not was_held:
			was_held = true 
		
		angular_velocity = Vector3.ZERO 
		
		var head_node = camera_node.get_parent()
		
		# 🎯 1. Hold Rotation Logic
		var custom_euler = Vector3(deg_to_rad(hold_rotation.x), deg_to_rad(hold_rotation.y), deg_to_rad(hold_rotation.z))
		var custom_rotation_basis = Basis.from_euler(custom_euler)
		var target_basis = (head_node.global_basis * custom_rotation_basis).orthonormalized()
		pivot.global_basis = pivot.global_basis.orthonormalized().slerp(target_basis, delta * lerp_speed)
		
		# 🎯 2. Hold Position Logic
		pivot.position = pivot.position.lerp(hold_position, delta * lerp_speed)
		
	else:
		if was_held:
			was_held = false
			
			# 🎯 3. Save, reset, and paste transforms on drop
			var drop_transform = pivot.global_transform
			pivot.transform = Transform3D.IDENTITY
			global_transform = drop_transform
	
	# 🌊 THE FAKE WATER SIMULATION
	# global_basis.y.y is 1.0 when standing up, 0.0 when flat, -1.0 when upside down
	var up_direction = global_basis.y.y
	
	# If the bottle is tilted mostly sideways or upside down...
	if up_direction < 0.2 and water_amount > 0.0:
		# 1. Drain the water level
		water_amount -= pour_speed * delta
		water_amount = clamp(water_amount, 0.0, 1.0)
		
		# 2. Visually shrink the water to the bottom
		if water_pivot:
			water_pivot.scale.y = water_amount
			
		print("Glug glug! Pouring water...")
