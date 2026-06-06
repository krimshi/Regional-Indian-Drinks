extends Area3D

@onready var hinge = $".." 

var is_open: bool = false
var target_rotation: float = 0.0
var current_player: CharacterBody3D = null

const OPEN_ANGLE: float = 90.0  # Adjust based on your preferred opening side
const CLOSE_ANGLE: float = 0.0
const SWING_SPEED: float = 6.0    

# The maximum distance (in meters) the player can walk away before the door shuts
const AUTO_CLOSE_DISTANCE: float = 4 

func interact(player):
	# Save a reference to the player who opened it so we can track their distance
	current_player = player
	toggle_door()

func toggle_door():
	is_open = !is_open
	if is_open:
		target_rotation = deg_to_rad(OPEN_ANGLE)
	else:
		target_rotation = deg_to_rad(CLOSE_ANGLE)
		current_player = null # Clear player reference when closed manually

func _process(delta: float):
	# Smoothly rotates the hinge to the target position
	hinge.rotation.y = move_toward(hinge.rotation.y, target_rotation, SWING_SPEED * delta)
	
	# If the door is open and we have a valid player reference, track their distance
	if is_open and is_instance_valid(current_player):
		var distance = global_position.distance_to(current_player.global_position)
		
		if distance > AUTO_CLOSE_DISTANCE:
			toggle_door() # Automatically triggers the close sequence
