extends RigidBody3D

@export_category("Holding Orientation")
@export var hold_rotation: Vector3 = Vector3.ZERO
@export var rotation_speed: float = 15.0

var is_held: bool = false
var camera_node: Camera3D = null
var was_held: bool = false 

# 🎯 Win Condition Variables
var win_triggered: bool = false 
@onready var state_node: Node3D = $State 
@onready var pivot: Node3D = $Pivot

func _physics_process(delta: float) -> void:
	if is_held and camera_node:
		
		# 🎯 THIS BLOCK RUNS ONCE WHEN GRABBED
		if not was_held:
			was_held = true 
			
			# Debug Print: Let's see what the glass sees!
			var is_state_visible = (state_node != null and state_node.visible)
			print("Glass grabbed! Is liquid visible? ", is_state_visible)
			
			# If this item is the Mixer Jar, tell the UI to hide
			if name.contains("Mixer_Jar"):
				get_tree().call_group("MixerUI", "hide")
				
			# 🏆 THE WIN CHECK (Moved inside the 'just grabbed' block for safety)
			if not win_triggered and is_state_visible:
				win_triggered = true
				print("🏆 Winning glass confirmed! Triggering Win Screen.")
				get_tree().call_group("WinScreen", "show_win_screen")
		
		# Stop physical tumbling while held
		angular_velocity = Vector3.ZERO 
		
		# Handle smooth rotation towards the camera
		var head_node = camera_node.get_parent()
		var custom_euler = Vector3(deg_to_rad(hold_rotation.x), deg_to_rad(hold_rotation.y), deg_to_rad(hold_rotation.z))
		var custom_rotation_basis = Basis.from_euler(custom_euler)
		var target_basis = (head_node.global_basis * custom_rotation_basis).orthonormalized()
		
		pivot.global_basis = pivot.global_basis.orthonormalized().slerp(target_basis, delta * rotation_speed)
		
	else:
		# Run this EXACTLY ONCE the moment you drop the item
		if was_held:
			was_held = false
			var drop_basis = pivot.global_basis.orthonormalized()
			pivot.transform.basis = Basis.IDENTITY
			global_basis = drop_basis

# ---------------------------------------------------------
# 🎯 BRIDGE FUNCTION FOR THE STRAINER ZONE
# ---------------------------------------------------------
func activate_strainer_zone() -> void:
	if has_node("StrainerDropZone"):
		$StrainerDropZone.activate_zone()
	else:
		print("WARNING: Glass Bowl cannot find 'StrainerDropZone' inside it!")
