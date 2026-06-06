extends StaticBody3D

@export var real_jar_scene: PackedScene # 🎯 Drag your HoldableJar.tscn here!
var blend_successful: bool = false

@onready var lid = $MixerLid 
@onready var state1 = $State1_Berries
@onready var state2 = $State2_Sugar
@onready var state3 = $State3_Water
@onready var real_jar = $Mixer_Jar

# Blade references
@onready var blade1 = $Jar/Blade1
@onready var blade2 = $Jar/Blade2

var is_ready_to_blend: bool = false
var is_spinning: bool = false
var spin_speed: float = 25.0

func _ready() -> void:
	# Make sure the fake liquids start invisible
	if state1: state1.visible = false
	if state2: state2.visible = false
	if state3: state3.visible = false

func _process(delta: float) -> void:
	if is_spinning:
		# 1. Spin the blades extremely fast
		if blade1: blade1.rotate_y(50.0 * delta)
		if blade2: blade2.rotate_y(50.0 * delta)
		
		# 2. Spin and wobble the State3 mesh to fake the liquid vortex!
		if state3 and state3.visible:
			state3.rotate_y(spin_speed * delta)
			
			var wobble = sin(Time.get_ticks_msec() * 0.05) * 0.08
			state3.scale.y = 1.0 + wobble
			state3.scale.x = 1.0 - (wobble / 2.0)
			state3.scale.z = 1.0 - (wobble / 2.0)

func start_spinning() -> void:
	is_spinning = true
	
	# 🎯 1. Instantly hide the solid berries and sugar!
	if state1: state1.visible = false
	if state2: state2.visible = false
	
	# 🎯 2. Smoothly blend the clear water into thick Phalsa juice!
	if state3:
		var mat = null
		if "material" in state3 and state3.material:
			mat = state3.material
		elif "material_override" in state3 and state3.material_override:
			mat = state3.material_override
		elif state3 is MeshInstance3D:
			mat = state3.get_active_material(0)
			
		if mat is StandardMaterial3D:
			var tween = create_tween()
			# We change the color to a deep magenta/purple, and set the Alpha (transparency) to 0.95 so it becomes almost entirely solid!
			tween.tween_property(mat, "albedo_color", Color(0.531, 0.127, 0.357, 0.95), 0.8)

func stop_spinning() -> void:
	is_spinning = false
	# Reset the liquid scale back to normal when it stops
	if state3:
		state3.scale = Vector3.ONE

func spoil_juice() -> void:
	if not state3: return
	
	# Find the material (Checks both normal meshes and CSG nodes)
	var mat = null
	if "material" in state3 and state3.material:
		mat = state3.material
	elif "material_override" in state3 and state3.material_override:
		mat = state3.material_override
	elif state3 is MeshInstance3D:
		mat = state3.get_active_material(0)
		
	if mat is StandardMaterial3D:
		var tween = create_tween()
		# Smoothly fade the color to a gross, murky brownish-green
		tween.tween_property(mat, "albedo_color", Color(0.4, 0.45, 0.2, 0.8), 0.5)
		print("Oh no! The juice is ruined!")

func set_fill_state(level: int) -> void:
	if level >= 1 and state1: state1.visible = true
	if level >= 2 and state2: state2.visible = true
	if level == 3 and state3:
		state3.visible = true
		is_ready_to_blend = true

func pop_lid() -> void:
	if not lid: return
	
	var tween = create_tween()
	# Pop it up slightly
	tween.tween_property(lid, "position:y", lid.position.y + 0.3, 0.3)
	# Fade it out 
	tween.tween_property(lid, "transparency", 1.0, 0.2)
	# Hide it completely
	tween.tween_callback(lid.hide)

func close_lid() -> void:
	if not lid: return
	
	# Unhide it before the animation starts so we can see it fade in
	lid.show() 
	
	var tween = create_tween()
	# Smoothly slide it back down by 0.3
	tween.tween_property(lid, "position:y", lid.position.y - 0.3, 0.3)
	# Fade it completely back to solid
	tween.tween_property(lid, "transparency", 0.0, 0.2)


# The UI calls this when the mini-game is won!
func set_blend_successful() -> void:
	print("Auto-Swapping the Jars!")
	
	# 1. Hide all the fake glued pieces
	if has_node("Jar"): $Jar.visible = false
	if lid: lid.visible = false
	if state3: state3.visible = false
	
	# 2. Wake up the real jar!
	if real_jar:
		real_jar.visible = true
		real_jar.process_mode = Node.PROCESS_MODE_INHERIT # Turns physics & collisions back on!
		
		# 3. Safely detach it from the Mixer base so the physics engine doesn't glitch!
		# We save its exact world position, unparent it, and move it to the main game world.
		var saved_transform = real_jar.global_transform
		remove_child(real_jar)
		get_tree().current_scene.add_child(real_jar)
		real_jar.global_transform = saved_transform
