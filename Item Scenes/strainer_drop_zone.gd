extends Area3D

@export var circle_glow: MeshInstance3D

var is_active: bool = false 
var pulse_tween: Tween
var overlapping_strainer: RigidBody3D = null # Tracks the strainer

func _ready() -> void:
	if circle_glow: circle_glow.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func activate_zone() -> void:
	is_active = true

func deactivate_zone() -> void:
	is_active = false
	if circle_glow: circle_glow.visible = false
	_stop_pulse()

func check_player_hands(held_item_name: String) -> void:
	if not is_active:
		if circle_glow: circle_glow.visible = false
		_stop_pulse()
		return
		
	var lower_name = held_item_name.to_lower()
	if lower_name.contains("strainer"):
		if not circle_glow.visible:
			circle_glow.visible = true
			_start_pulse()
	else:
		if circle_glow: circle_glow.visible = false
		_stop_pulse()

func _on_body_entered(body: Node3D) -> void:
	if not is_active: return
	if body is RigidBody3D and body.name.to_lower().contains("strainer"):
		# 🎯 Just remember the strainer entered the bowl!
		overlapping_strainer = body

func _on_body_exited(body: Node3D) -> void:
	if body == overlapping_strainer:
		overlapping_strainer = null

func _physics_process(_delta: float) -> void:
	# 🎯 THE MAGIC: Wait for the player to let go of the Strainer!
	if is_active and overlapping_strainer != null:
		if "is_held" in overlapping_strainer and overlapping_strainer.is_held == false:
			
			print("Strainer successfully dropped into the bowl!")
			
			# 1. The Blindfold Trick: Turn them invisible instantly to stop 1-frame bumps
			overlapping_strainer.visible = false
			get_parent().visible = false
			
			# 2. Shout to the Counter to do the final swap!
			get_tree().call_group("SquareCounterZone", "trigger_final_assembly_swap")
			
			# 3. Delete the Strainer forever
			overlapping_strainer.queue_free()
			overlapping_strainer = null

# --- VISUALS ---
func _start_pulse() -> void:
	if pulse_tween and pulse_tween.is_valid(): pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(circle_glow, "transparency", 0.65, 0.6).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(circle_glow, "transparency", 0.0, 0.6).set_trans(Tween.TRANS_SINE)

func _stop_pulse() -> void:
	if pulse_tween and pulse_tween.is_valid(): pulse_tween.kill()
	if circle_glow: circle_glow.transparency = 0.0
