extends Area3D

@onready var hinge = $".." 

# This lets you drag and drop your drawer into the Inspector
@export var inside_drawer: AnimatableBody3D 

var is_open: bool = false
var target_rotation: float = 0.0
var current_player: CharacterBody3D = null

const OPEN_ANGLE: float = 90.0  
const CLOSE_ANGLE: float = 0.0
const SWING_SPEED: float = 6.0    
const AUTO_CLOSE_DISTANCE: float = 4 

func interact(player):
	current_player = player
	toggle_door()

func toggle_door():
	is_open = !is_open
	if is_open:
		target_rotation = deg_to_rad(OPEN_ANGLE)
	else:
		target_rotation = deg_to_rad(CLOSE_ANGLE)
		current_player = null 
		
		# 🗄️ Force the drawer inside to close when the door shuts!
		if inside_drawer and inside_drawer.has_method("force_close"):
			inside_drawer.force_close()

func _process(delta: float):
	hinge.rotation.y = move_toward(hinge.rotation.y, target_rotation, SWING_SPEED * delta)
	
	if is_open and is_instance_valid(current_player):
		var distance = global_position.distance_to(current_player.global_position)
		if distance > AUTO_CLOSE_DISTANCE:
			toggle_door()
