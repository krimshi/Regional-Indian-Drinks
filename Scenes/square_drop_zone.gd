extends Area3D

@export var glow_plane: MeshInstance3D
@export var combined_static_assembly: StaticBody3D # The final model
@export var water_pour_target: Marker3D # Drop your Marker3D target here!

var accepted_items: Array = ["Glass_Bowl"]
var placed_items: Array = []
var item_nodes: Dictionary = {} 
var pulse_tween: Tween

func _ready() -> void:
	if glow_plane: glow_plane.visible = false
	
	if combined_static_assembly:
		combined_static_assembly.visible = false
		combined_static_assembly.process_mode = Node.PROCESS_MODE_DISABLED
		
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func check_player_hands(held_item_name: String) -> void:
	var is_holding_correct_item = false
	
	if combined_static_assembly and combined_static_assembly.visible:
		if held_item_name.contains("Mixer_Jar"):
			is_holding_correct_item = true
	else:
		for req in accepted_items:
			if held_item_name.contains(req):
				is_holding_correct_item = true
				break

	if is_holding_correct_item and placed_items.size() < 1:
		if not glow_plane.visible:
			glow_plane.visible = true
			_start_pulse()
	else:
		if glow_plane: glow_plane.visible = false
		_stop_pulse()

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		if combined_static_assembly and combined_static_assembly.visible and body.name.contains("Mixer_Jar"):
			print("🎯 Mixer Jar dropped! Starting cinematic sequence.")
			_stop_pulse()
			if glow_plane: glow_plane.visible = false
			
			_run_full_pour_sequence(body)
			return

		for req in accepted_items:
			if body.name.contains(req) and not placed_items.has(req):
				if placed_items.size() < 1:
					placed_items.append(req)
					item_nodes[req] = body 
					
					if body.has_node("StrainerDropZone"):
						body.get_node("StrainerDropZone").activate_zone()

func _on_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		for req in accepted_items:
			if body.name.contains(req) and placed_items.has(req):
				placed_items.erase(req)
				item_nodes.erase(req)
				
				if body.has_node("StrainerDropZone"):
					body.get_node("StrainerDropZone").deactivate_zone()

# ---------------------------------------------------------
# 🎬 THE FINAL ASSEMBLY SWAP
# ---------------------------------------------------------
func trigger_final_assembly_swap() -> void:
	for item_name in item_nodes:
		var item = item_nodes[item_name]
		if is_instance_valid(item):
			item.queue_free()
			
	placed_items.clear()
	item_nodes.clear()
			
	if combined_static_assembly:
		combined_static_assembly.visible = true
		combined_static_assembly.process_mode = Node.PROCESS_MODE_INHERIT
		
	if glow_plane: glow_plane.visible = false
	_stop_pulse()


# ---------------------------------------------------------
# 🌊 CINEMATIC ANIMATION SYSTEM
# ---------------------------------------------------------
func _run_full_pour_sequence(jar: RigidBody3D) -> void:
	if not water_pour_target:
		print("❌ Error: WaterPourTarget Marker3D is missing!")
		return

	# 1. Freeze item so it doesn't get bumped
	jar.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	jar.freeze = true

	# 🎯 THE FIX: Bulletproof recursive search for the nodes!
	# (true, false) tells Godot to search every single folder inside the jar
	var lid = jar.find_child("MixerLid", true, false)
	var water = jar.find_child("State3_Water", true, false)

	if not water:
		print("⚠️ Warning: Could not find State3_Water inside the jar!")

	# 3. Pop the Mixer Lid off!
	if lid: lid.visible = false
	
	await get_tree().create_timer(0.2).timeout

	# 4. POUR THE WATER
	await _animate_pour(jar, water_pour_target, water)

	# 5. RETURN THE LID
	if lid: lid.visible = true
	
# 6. UNFREEZE AND CLEANUP
	jar.freeze = false
	print("✅ Sequence Complete! Jar returned to player.")
	
	# 🎯 THE NEW TRIGGER: Start the stirring minigame!
	if combined_static_assembly and combined_static_assembly.has_method("start_stirring_minigame"):
		combined_static_assembly.start_stirring_minigame()
	
	
	# Reveal 'State1' on the final assembly!
	if combined_static_assembly:
		var state1 = combined_static_assembly.get_node_or_null("state1")
		if not state1:
			state1 = combined_static_assembly.get_node_or_null("State1")
			
		if state1:
			state1.visible = true
			print("💧 Strainer liquid revealed!")
		else:
			print("⚠️ Could not find State1 inside the Combined Assembly.")
	
	queue_free() # Destroy the zone

# 🎯 Sequential animation function
func _animate_pour(item: RigidBody3D, target_marker: Marker3D, water_node: Node3D) -> void:
	var original_pos = item.global_position
	var original_rot = item.rotation_degrees
	
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(item, "global_position", target_marker.global_position, 0.8)
	tween.tween_property(item, "rotation_degrees:z", original_rot.z + 75.0, 0.5)
	tween.tween_interval(1.2)
	
	tween.tween_callback(func():
		if water_node: water_node.visible = false
		print("💧 Water emptied out!")
	)
	
	tween.tween_property(item, "rotation_degrees:z", original_rot.z, 0.5)
	tween.tween_property(item, "global_position", original_pos, 0.8)
	
	await tween.finished


# --- VISUALS ---
func _start_pulse() -> void:
	if pulse_tween and pulse_tween.is_valid(): pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(glow_plane, "transparency", 0.65, 0.6).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(glow_plane, "transparency", 0.0, 0.6).set_trans(Tween.TRANS_SINE)

func _stop_pulse() -> void:
	if pulse_tween and pulse_tween.is_valid(): pulse_tween.kill()
	if glow_plane: glow_plane.transparency = 0.0
