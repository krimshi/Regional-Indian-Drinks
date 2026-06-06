extends Area3D

@onready var handle = get_parent()
@onready var water_raycast = get_node("../../Spout/WaterRayCast")
@onready var stream_mesh = get_node("../../Spout/StreamMesh")

var is_flowing : bool = false
var player : Node3D

func _ready():
	stream_mesh.visible = false
	player = get_tree().get_first_node_in_group("Player")
	
	# 🎯 THE FIX: Detach the cylinder from the Tap's weird rotation/scale!
	stream_mesh.top_level = true

func interact(_body = null) -> void:
	is_flowing = !is_flowing
	var tween = create_tween()
	
	if is_flowing:
		# 🎯 FIX 1: Changed to -45.0! (Swap the 'z' to 'x' or 'y' if it rotates weirdly)
		tween.tween_property(handle, "rotation_degrees:x", -45.0, 0.2)
		stream_mesh.visible = true
	else:
		tween.tween_property(handle, "rotation_degrees:x", 0.0, 0.2)
		stream_mesh.visible = false

func _physics_process(_delta: float) -> void:
	if is_flowing and player:
		if global_position.distance_to(player.global_position) > 4:
			interact() 
			
	if is_flowing and water_raycast.is_colliding():
		var hit_point = water_raycast.get_collision_point()
		var spout_pos = water_raycast.global_position
		
		var distance = spout_pos.distance_to(hit_point)
		
		# 🎯 THE FIX: Use scale.y instead of height for the MeshInstance3D
		stream_mesh.scale.y = distance
		
		stream_mesh.global_position = spout_pos.lerp(hit_point, 0.5)
		stream_mesh.global_rotation = Vector3.ZERO
	
	if is_flowing and water_raycast.is_colliding():
		var hit_point = water_raycast.get_collision_point()
		var spout_pos = water_raycast.global_position
		var distance = spout_pos.distance_to(hit_point)
		
		stream_mesh.scale.y = distance
		stream_mesh.global_position = spout_pos.lerp(hit_point, 0.5)
		stream_mesh.global_rotation = Vector3.ZERO
		
		# 🎯 NEW: Tell whatever we are hitting that it is being washed!
		var collider = water_raycast.get_collider()
		if collider and collider.has_method("wash_berries"):
			collider.wash_berries()
