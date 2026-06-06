extends StaticBody3D

func interact(_player) -> void:
	# Tell the mixer to run the swap!
	get_parent().perform_fake_swap()
