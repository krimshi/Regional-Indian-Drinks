extends StaticBody3D

@export_category("Final Reward & Next Steps")
@export var final_sharbat_bowl: RigidBody3D 
@export var juice_make_zone: Node3D # 🎯 NEW: Your next drop zone!

@onready var state1 = $State1
@onready var state2 = $State2
@onready var state3 = $State3

@onready var glow_points: Array[Area3D] = [$Top, $Right, $Bottom, $Left]

var current_round: int = 0
var current_target_index: int = 0
var is_minigame_active: bool = false
var hit_cooldown: bool = false 

func _ready() -> void:
	if state1: state1.visible = false
	if state2: state2.visible = false
	if state3: state3.visible = false
	
	if final_sharbat_bowl:
		final_sharbat_bowl.visible = false
		final_sharbat_bowl.process_mode = Node.PROCESS_MODE_DISABLED
		
	# 🎯 Safety Check: Ensure the Juice zone starts off!
	if juice_make_zone:
		juice_make_zone.visible = false
		juice_make_zone.process_mode = Node.PROCESS_MODE_DISABLED
	
	for i in range(glow_points.size()):
		var point = glow_points[i]
		point.visible = false
		point.process_mode = Node.PROCESS_MODE_DISABLED
		point.body_entered.connect(_on_point_touched.bind(i))

# ---------------------------------------------------------
# 🎮 MINIGAME LOGIC
# ---------------------------------------------------------
func start_stirring_minigame() -> void:
	print("🥄 Stirring Minigame Started!")
	is_minigame_active = true
	current_round = 0
	current_target_index = 0
	hit_cooldown = false
	
	if state1: state1.visible = true
	_activate_target(0)

func _on_point_touched(body: Node3D, point_index: int) -> void:
	if not is_minigame_active or hit_cooldown: return
	
	if body.is_in_group("Spatula") or body.name.to_lower().contains("spatula"):
		if point_index == current_target_index:
			_hit_correct_target(body)

func _hit_correct_target(spatula: Node3D) -> void:
	hit_cooldown = true
	get_tree().create_timer(0.25).timeout.connect(func(): hit_cooldown = false)
	
	var current_point = glow_points[current_target_index]
	current_point.visible = false
	current_point.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	
	current_target_index += 1
	
	if current_target_index >= 4:
		current_target_index = 0
		current_round += 1
		_advance_liquid_state.call_deferred(spatula)
		
	if current_round < 2:
		_activate_target(current_target_index)

# ---------------------------------------------------------
# 💧 THE LIQUID SWAP FUNCTION
# ---------------------------------------------------------
func _advance_liquid_state(spatula: Node3D) -> void:
	if current_round == 1:
		print("🔄 Round 1 Complete! Swapping State 1 for State 2.")
		if state1: state1.visible = false
		if state2: state2.visible = true
		
	elif current_round == 2:
		print("🎉 Minigame Complete! Spawning final Sharbat Bowl.")
		is_minigame_active = false
		
		# 1. Turn on the real physics bowl!
		if final_sharbat_bowl:
			final_sharbat_bowl.visible = true
			final_sharbat_bowl.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
			final_sharbat_bowl.set_deferred("freeze", false) 
			
		# 🎯 2. NEW FIX: Turn on the JuiceMakeZone so the player can continue!
		if juice_make_zone:
			juice_make_zone.visible = true
			juice_make_zone.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
			print("✅ Juice Make Zone is now active!")
			
		# 3. Obliterate the Spatula from the player's hands!
		if is_instance_valid(spatula):
			spatula.queue_free()
		
		# 4. Obliterate this entire station!
		queue_free()

# ---------------------------------------------------------
# ✨ VISUALS & PHYSICS TOGGLE
# ---------------------------------------------------------
func _activate_target(index: int) -> void:
	for point in glow_points:
		point.visible = false
		point.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	
	var active_point = glow_points[index]
	active_point.visible = true
	active_point.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
