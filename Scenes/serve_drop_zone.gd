extends Area3D

@export var glow_plane: MeshInstance3D

var pulse_tween: Tween

# 🎯 THE MAGIC LOCK
var sequence_started: bool = false

# Memory for the cinematic
var tracked_bowl: RigidBody3D = null
var tracked_tray: RigidBody3D = null
var tracked_glasses: Array[RigidBody3D] = []

func _ready() -> void:
	if glow_plane: glow_plane.visible = false

# ---------------------------------------------------------
# 🔦 RAYCAST DETECTION (Called by player.gd)
# ---------------------------------------------------------
func check_player_hands(held_item_name: String) -> void:
	if sequence_started:
		if glow_plane: glow_plane.visible = false
		_stop_pulse()
		return

	var lower_name = held_item_name.to_lower()
	var is_valid_item = false

	# Accept the bowl, tray, or any glass
	if lower_name.contains("phalsa_sharbat_bowl") or lower_name.contains("ice_tray") or lower_name.contains("glass"):
		is_valid_item = true

	if is_valid_item:
		if not glow_plane.visible:
			glow_plane.visible = true
			_start_pulse()
	else:
		if glow_plane: glow_plane.visible = false
		_stop_pulse()

# ---------------------------------------------------------
# 🎯 THE RADAR SYSTEM (Detects everything dynamically)
# ---------------------------------------------------------
func _physics_process(_delta: float) -> void:
	if sequence_started: return

	var current_bowl = null
	var current_tray = null
	var current_glasses: Array[RigidBody3D] = []

	for body in get_overlapping_bodies():
		if not is_instance_valid(body) or not body is RigidBody3D: continue

		# Ignore items currently held by the player
		if "is_held" in body and body.is_held == true: continue

		var b_name = body.name.to_lower()

		if b_name.contains("phalsa_sharbat_bowl"):
			current_bowl = body
		elif b_name.contains("ice_tray"):
			current_tray = body
		elif b_name.contains("glass"):
			# 🎯 THE FILTER: Only track glasses that have an INVISIBLE State!
			var state_node = body.find_child("State", true, false)
			if state_node and not state_node.visible:
				current_glasses.append(body)

	# Update our global tracking variables
	tracked_bowl = current_bowl
	tracked_tray = current_tray
	tracked_glasses = current_glasses

	_check_completion()

# ---------------------------------------------------------
# ✅ COMPLETION CHECK
# ---------------------------------------------------------
func _check_completion() -> void:
	# Trigger ONLY if we have the bowl, the tray, AND at least one unfilled glass!
	if tracked_bowl and tracked_tray and tracked_glasses.size() > 0 and not sequence_started:
		
		# 🚪 SLAM THE DOOR SHUT!
		sequence_started = true
		
		print("🎉 Ready to serve! Found " + str(tracked_glasses.size()) + " empty glasses.")
		if glow_plane: glow_plane.visible = false
		_stop_pulse()
		
		_run_serve_sequence()

# ---------------------------------------------------------
# 🎬 THE SERVING CINEMATIC
# ---------------------------------------------------------
func _run_serve_sequence() -> void:
	print("Starting Serve Sequence!")

	# 1. Freeze everything so they don't bounce (Kinematic prevents snapping!)
	tracked_bowl.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	tracked_bowl.set_deferred("freeze", true)
	
	tracked_tray.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	tracked_tray.set_deferred("freeze", true)
	
	for glass in tracked_glasses:
		glass.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		glass.set_deferred("freeze", true)

	await get_tree().create_timer(0.5).timeout

	# 2. Iterate through EVERY unfilled glass found in the zone!
	for glass in tracked_glasses:
		var pour_target = glass.find_child("PourTarget", true, false)
		var state_node = glass.find_child("State", true, false)

		if not pour_target:
			print("⚠️ Warning: Glass is missing 'PourTarget' Marker3D!")
			continue

		# 🧊 Pour Ice First
		print("🧊 Pouring Ice into " + glass.name + "...")
		await _animate_pour(tracked_tray, pour_target)

		# 🍷 Pour Sharbat Second
		print("🍷 Pouring Sharbat into " + glass.name + "...")
		await _animate_pour(tracked_bowl, pour_target)

		# ✨ Reveal the liquid!
		if state_node:
			state_node.visible = true
			print("✨ " + glass.name + " is filled!")

	# 3. UNFREEZE AND CLEANUP
	tracked_bowl.set_deferred("freeze", false)
	tracked_tray.set_deferred("freeze", false)
	
	for glass in tracked_glasses:
		glass.set_deferred("freeze", false)

	print("✅ Serving Complete! Enjoy the Sharbat.")
	queue_free() # Destroy the zone so it doesn't trigger again

# ---------------------------------------------------------
# 🔄 RESTORED: PERFECT ANIMATION SCRIPT
# ---------------------------------------------------------
func _animate_pour(item: RigidBody3D, target_marker: Node3D) -> void:
	var original_pos = item.global_position
	var original_rot = item.rotation_degrees
	
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	# Move item slightly above the glass marker
	tween.tween_property(item, "global_position", target_marker.global_position, 0.8)
	
	# Tilt to pour (100 degrees)
	tween.tween_property(item, "rotation_degrees:z", original_rot.z + 100.0, 0.5)
	
	# Wait for imaginary contents to fall (Reduced to 1.0s so a 4-glass pour isn't too slow)
	tween.tween_interval(1.0)
	
	# Tilt back
	tween.tween_property(item, "rotation_degrees:z", original_rot.z, 0.5)
	
	# Move back to resting spot
	tween.tween_property(item, "global_position", original_pos, 0.8)
	
	await tween.finished

# ---------------------------------------------------------
# ✨ VISUALS
# ---------------------------------------------------------
func _start_pulse() -> void:
	if pulse_tween and pulse_tween.is_valid(): pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(glow_plane, "transparency", 0.65, 0.6).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(glow_plane, "transparency", 0.0, 0.6).set_trans(Tween.TRANS_SINE)

func _stop_pulse() -> void:
	if pulse_tween and pulse_tween.is_valid(): pulse_tween.kill()
	if glow_plane: glow_plane.transparency = 0.0
