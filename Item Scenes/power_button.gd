extends StaticBody3D

@onready var mesh = $Button # Adjust if your mesh has a different name!
var is_on: bool = false
var is_active: bool = true # Used to lock the button after winning

func interact(_player) -> void:
	if not is_active: 
		return
		
	# 🎯 NEW: Ask the parent (Mixer_Grinder) if it is fully loaded!
	if not get_parent().is_ready_to_blend:
		print("Cannot turn on! Ingredients are missing.")
		return # Stop right here and don't turn on
		
	# Flip the switch! 
	is_on = !is_on
	_update_glow()
	
	# Shout out to the UI to start or stop the mini-game!
	get_tree().call_group("MixerUI", "toggle_blender", is_on)

func _update_glow() -> void:
	# 🎯 THE FIX: CSG nodes store their material in the '.material' property!
	var mat = mesh.material as StandardMaterial3D
	
	# (Just in case you put it in the Override slot instead of the main Material slot)
	if not mat:
		mat = mesh.material_override as StandardMaterial3D
		
	if mat:
		# Safety check: Force emission to turn on just in case it got unchecked
		mat.emission_enabled = true 
		
		# Turn the energy up to 2.0 when on, and drop it to 0.0 when off
		mat.emission_energy_multiplier = 2.0 if is_on else 0.0
	else:
		print("ERROR: No material found on the CSG button!")

# The UI will call this to forcefully shut the button off if the player fails
func force_off() -> void:
	is_on = false
	_update_glow()
