extends RigidBody3D

@export_category("Holding Orientation")
@export var hold_rotation: Vector3 = Vector3.ZERO
@export var rotation_speed: float = 15.0

var is_held: bool = false
var camera_node: Camera3D = null
var was_held: bool = false 

@onready var pivot: Node3D = $Pivot

# 🎯 NEW: Safely track if we won so it doesn't spam
var win_triggered: bool = false

func _physics_process(delta: float) -> void:
	if is_held and camera_node:
		
		# 🎯 This block runs exactly ONCE the moment you grab the item
		if not was_held:
			was_held = true 
			
			# ---------------------------------------------------------
			# 🏆 SAFE WIN CONDITION (Won't crash other items!)
			# ---------------------------------------------------------
			# 1. Safely check if this specific item has a "State" node
			var state_node = find_child("State", true, false)
			
			# 2. Make sure this is actually a glass, it has a state, and it is visible!
			if name.to_lower().contains("glass") and state_node and state_node.visible:
				if not win_triggered:
					win_triggered = true
					print("🏆 Winning glass picked up! Triggering Win Screen.")
					get_tree().call_group("WinScreen", "show_win_screen")
			# ---------------------------------------------------------
			
			# If this item is the Mixer Jar, tell the UI to instantly hide!
			if name.contains("Mixer_Jar"):
				get_tree().call_group("MixerUI", "hide")
		
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
		
	else:
		# Run this EXACTLY ONCE the moment you drop the item
		if was_held:
			was_held = false
			
			# 1. Save the exact angle the item is facing on your screen
			var drop_basis = pivot.global_basis.orthonormalized()
			
			# 2. Instantly reset the visual folder back to zero
			pivot.transform.basis = Basis.IDENTITY
			
			# 3. Paste the saved angle onto the root physics body!
			global_basis = drop_basis

# ---------------------------------------------------------
# 🎯 BRIDGE FUNCTION FOR THE STRAINER ZONE
# ---------------------------------------------------------
func activate_strainer_zone() -> void:
	if has_node("StrainerDropZone"):
		$StrainerDropZone.activate_zone()
	else:
		print("WARNING: Glass Bowl cannot find 'StrainerDropZone' inside it!")
