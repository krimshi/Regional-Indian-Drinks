extends StaticBody3D # (Change to RigidBody3D if your book uses physics)

# Your player.gd script automatically calls this when you Right-Click!
func interact(_player_node) -> void:
	print("Reading Recipe Book...")
	get_tree().call_group("RecipeBookUI", "show_book")
