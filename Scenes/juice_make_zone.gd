extends Area3D

@export var glow_plane: MeshInstance3D

var accepted_items: Array = ["Extracted_Sharbat_Bowl", "Black_Salt", "Roasted_Cumin_Powder", "Water_Bottle"]
var placed_items: Array = []
var item_nodes: Dictionary = {} 
var pulse_tween: Tween

# 🎯 THE MAGIC LOCK: This stops the overlapping chaos!
var sequence_started: bool = false

func _ready() -> void:
	if glow_plane: glow_plane.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# ---------------------------------------------------------
# 🔦 RAYCAST DETECTION (Called by player.gd)
# ---------------------------------------------------------
func check_player_hands(held_item_name: String) -> void:
	if placed_items.size() >= 4 or sequence_started:
		if glow_plane: glow_plane.visible = false
		_stop_pulse()
		return
		
	var is_holding_correct_item = false
	var lower_name = held_item_name.to_lower()
	
	for req in accepted_items:
		if lower_name.contains(req.to_lower()):
			is_holding_correct_item = true
			break

	if is_holding_correct_item:
		if not glow_plane.visible:
			glow_plane.visible = true
			_start_pulse()
	else:
		if glow_plane: glow_plane.visible = false
		_stop_pulse()

# ---------------------------------------------------------
# 📦 PHYSICAL DROPPING LOGIC
# ---------------------------------------------------------
func _on_body_entered(body: Node3D) -> void:
	if sequence_started or not is_instance_valid(body) or not body is RigidBody3D: return
	
	var b_name = body.name.to_lower()
	
	for req in accepted_items:
		var req_lower = req.to_lower()
		
		if b_name.contains(req_lower) and not placed_items.has(req):
			placed_items.append(req)
			item_nodes[req] = body
			print(req + " safely placed in Juice Make Zone!")
			
			_check_completion()

func _on_body_exited(body: Node3D) -> void:
	if sequence_started or not is_instance_valid(body) or not body is RigidBody3D: return
	
	var b_name = body.name.to_lower()
	
	for req in accepted_items:
		var req_lower = req.to_lower()
		
		if b_name.contains(req_lower) and placed_items.has(req):
			placed_items.erase(req)
			item_nodes.erase(req)
			print(req + " removed from Juice Make Zone!")

# ---------------------------------------------------------
# 🎯 THE MEMORY WIPE FIX
# ---------------------------------------------------------
func _physics_process(_delta: float) -> void:
	if sequence_started: return 
	
	var keys_to_remove = []
	for key in item_nodes.keys():
		var item = item_nodes[key]
		if is_instance_valid(item) and "is_held" in item and item.is_held == true:
			keys_to_remove.append(key)
				
	for key in keys_to_remove:
		placed_items.erase(key)
		item_nodes.erase(key)

# ---------------------------------------------------------
# ✅ COMPLETION CHECK
# ---------------------------------------------------------
func _check_completion() -> void:
	if placed_items.size() == 4 and not sequence_started:
		sequence_started = true 
		
		print("🎉 All 4 ingredients gathered! Starting final pour sequence.")
		if glow_plane: glow_plane.visible = false
		_stop_pulse()
		
		_run_final_pour_sequence()

# ---------------------------------------------------------
# 🎬 THE CINEMATIC POURING SYSTEM
# ---------------------------------------------------------
func _run_final_pour_sequence() -> void:
	print("Starting Cinematic Sequence!")

	var bowl = item_nodes.get("Extracted_Sharbat_Bowl")
	var salt = item_nodes.get("Black_Salt")
	var cumin = item_nodes.get("Roasted_Cumin_Powder")
	var water = item_nodes.get("Water_Bottle")
	
	if not bowl or not salt or not cumin or not water:
		print("❌ Error: Missing an ingredient for the animation!")
		return

	var pour_target = bowl.find_child("PourTarget", true, false)
	if not pour_target:
		print("❌ Error: Could not find 'PourTarget' Marker3D!")
		return

	# 1. Back to your EXACT simple freeze logic
	bowl.freeze = true
	salt.freeze = true
	cumin.freeze = true
	water.freeze = true

	await get_tree().create_timer(0.5).timeout

	# 2. POUR THE SALT
	var salt_cap = salt.find_child("Cap", true, false)
	if salt_cap: salt_cap.visible = false
	
	print("🧂 Pouring Black Salt...")
	await _animate_pour(salt, pour_target)
	
	if salt_cap: salt_cap.visible = true
	
	# 3. POUR THE CUMIN
	var cumin_cap = cumin.find_child("Cap", true, false)
	if cumin_cap: cumin_cap.visible = false
	
	print("🌿 Pouring Roasted Cumin Powder...")
	await _animate_pour(cumin, pour_target)
	
	if cumin_cap: cumin_cap.visible = true
	
	# 4. POUR THE WATER
	var water_cap = water.find_child("Cap", true, false)
	if water_cap: water_cap.visible = false
	
	print("💧 Pouring Water...")
	await _animate_pour(water, pour_target)
	
	if water_cap: water_cap.visible = true

	# 5. UNFREEZE AND CLEANUP
	bowl.freeze = false
	salt.freeze = false
	cumin.freeze = false
	water.freeze = false
	
	# ---------------------------------------------------------
	# 🎯 NEW: REVEAL STATE AND RENAME BOWL
	# ---------------------------------------------------------
	var bowl_state = bowl.find_child("State", true, false)
	if bowl_state:
		bowl_state.visible = true
		print("✨ Final liquid state revealed!")
		
	# Instantly rename the root node so the player Raycast reads it perfectly!
	bowl.name = "Phalsa_Sharbat_Bowl"
	print("🏆 Bowl renamed to: " + bowl.name)
	# ---------------------------------------------------------
	
	print("✅ Sequence Complete! The Phalsa Sharbat is ready.")
	queue_free()

# ---------------------------------------------------------
# 🔄 RESTORED: YOUR EXACT ANIMATION SCRIPT (FIXED FOR CHOPPINESS)
# ---------------------------------------------------------
func _animate_pour(item: RigidBody3D, target_marker: Node3D) -> void:
	var original_pos = item.global_position
	# 🎯 THE FIX: Explicitly grab full Degrees vector!
	var original_rot_deg = item.rotation_degrees 
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	# Move item to whichever marker we passed in!
	tween.tween_property(item, "global_position", target_marker.global_position, 0.8)
	
	# Calculate target rotation safely
	var pour_rot = original_rot_deg
	pour_rot.z += 100.0
	
	# Tilt it sideways to pour (Tweening the whole vector stops snapping)
	tween.tween_property(item, "rotation_degrees", pour_rot, 0.5)
	
	# Wait 1.5 seconds for the imaginary contents to fall out
	tween.tween_interval(1.5)
	
	# Tilt it back upright
	tween.tween_property(item, "rotation_degrees", original_rot_deg, 0.5)
	
	# Put it exactly back where the player left it on the counter
	tween.tween_property(item, "global_position", original_pos, 0.8)
	
	# Pause the script until this entire tween sequence finishes
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
