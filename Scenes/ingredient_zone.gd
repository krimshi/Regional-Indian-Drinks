extends Area3D

@export var glow_plane: MeshInstance3D
@export var pour_target: Marker3D
@export var water_pour_target: Marker3D
@export var mixer_grinder: Node3D

var required_items: Array = ["Washed_Phalsa_Berries", "Water_Bottle", "Sugar"]
var placed_items: Array = []
var item_nodes: Dictionary = {} # 🎯 NEW: Tracks the exact physical objects!
var pulse_tween: Tween

func _ready() -> void:
	if glow_plane: glow_plane.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func check_player_hands(held_item_name: String) -> void:
	if held_item_name in required_items and placed_items.size() < 3:
		if not glow_plane.visible:
			glow_plane.visible = true
			_start_pulse()
	else:
		glow_plane.visible = false
		_stop_pulse()

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		for req in required_items:
			if body.name.contains(req) and not placed_items.has(req):
				placed_items.append(req)
				item_nodes[req] = body # Save the exact node!
				_check_completion()

func _on_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		for req in required_items:
			if body.name.contains(req) and placed_items.has(req):
				placed_items.erase(req)
				item_nodes.erase(req)

func _check_completion() -> void:
	if placed_items.size() == required_items.size():
		glow_plane.visible = false 
		_stop_pulse() 
		get_tree().call_group("RecipeMenu", "show_menu")

# --- 🎬 PHASE 3: THE AUTO-ANIMATION ---

# The UI script will call this function when the button is pressed!
func start_cinematic() -> void:
	print("Starting Cinematic Sequence!")
	
	var basket = item_nodes["Washed_Phalsa_Berries"]
	var water = item_nodes["Water_Bottle"]
	var sugar = item_nodes["Sugar"]
	
	# 1. Freeze all items so they don't get bumped
	basket.freeze = true
	water.freeze = true
	sugar.freeze = true
	
	# 2. Pop the Mixer Lid off first!
	if mixer_grinder and mixer_grinder.has_method("pop_lid"):
		mixer_grinder.pop_lid()
		await get_tree().create_timer(0.5).timeout

	# 3. POUR THE BERRIES
	await _animate_pour(basket, pour_target)
	
	# 🎯 THE FIX: Call our new clean function on the item!
	if basket.has_method("empty_basket"):
		basket.empty_basket()
		
	if mixer_grinder: mixer_grinder.set_fill_state(1)
	
	# 4. POUR THE SUGAR
	if sugar.has_node("Pivot/Lid"): 
		var lid = sugar.get_node("Pivot/Lid")
		lid.position.y += 0.2
		lid.visible = false
	await _animate_pour(sugar, pour_target)
	if mixer_grinder: mixer_grinder.set_fill_state(2)
	
	# 5. POUR THE WATER
	if water.has_node("Pivot/Cap"): 
		water.get_node("Pivot/Cap").visible = false
	await _animate_pour(water, water_pour_target)
	
	if "water_amount" in water:
		water.water_amount = 0.5 
		water.water_pivot.scale.y = 0.5
	if mixer_grinder: mixer_grinder.set_fill_state(3)
	
	# 🎯 NEW: 6. RETURN ALL LIDS AND CAPS
	# Put the sugar lid back down and make it visible
	if sugar.has_node("Pivot/Lid"):
		var sugar_lid = sugar.get_node("Pivot/Lid")
		sugar_lid.position.y -= 0.2 # Slide it back down
		sugar_lid.visible = true
		
	# Put the water cap back on
	if water.has_node("Pivot/Cap"):
		water.get_node("Pivot/Cap").visible = true
		
	# Tell the mixer to play its close lid animation
	if mixer_grinder and mixer_grinder.has_method("close_lid"):
		mixer_grinder.close_lid()
		# Wait half a second for the mixer lid animation to finish
		await get_tree().create_timer(0.5).timeout 
		
	# ---------------------------------------------------------
	
	# 🎯 THE FIX: Unfreeze the items so gravity and player grabbing works again!
	if is_instance_valid(basket): basket.freeze = false
	if is_instance_valid(water): water.freeze = false
	if is_instance_valid(sugar): sugar.freeze = false
	
	print("Sequence Complete! Ready to Blend.")
	
	# Permanently destroy the invisible detector so the zone is dead!
	queue_free()

# 🎯 NEW: Added 'target_marker' to the function
func _animate_pour(item: RigidBody3D, target_marker: Marker3D) -> void:
	var original_pos = item.global_position
	var original_rot = item.global_rotation
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	# Move item to whichever marker we passed in!
	tween.tween_property(item, "global_position", target_marker.global_position, 0.8)
	
	# Tilt it sideways to pour
	tween.tween_property(item, "rotation_degrees:z", original_rot.z + 100.0, 0.5)
	
	# Wait 1.5 seconds for the imaginary contents to fall out
	tween.tween_interval(1.5)
	
	# Tilt it back upright
	tween.tween_property(item, "rotation_degrees:z", original_rot.z, 0.5)
	
	# Put it exactly back where the player left it on the counter
	tween.tween_property(item, "global_position", original_pos, 0.8)
	
	# Pause the script until this entire tween sequence finishes
	await tween.finished

# --- PULSE ANIMATION LOGIC (UNCHANGED) ---
func _start_pulse() -> void:
	if pulse_tween and pulse_tween.is_valid(): pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(glow_plane, "transparency", 0.65, 0.6).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(glow_plane, "transparency", 0.0, 0.6).set_trans(Tween.TRANS_SINE)

func _stop_pulse() -> void:
	if pulse_tween and pulse_tween.is_valid(): pulse_tween.kill()
	if glow_plane: glow_plane.transparency = 0.0
