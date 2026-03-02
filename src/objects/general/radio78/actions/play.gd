extends R_RadioAction

func _server_selected_world(object: Node3D, raycast: CT_InteractionRay) -> void:
	super(object, raycast)
	if not radio:
		return
	
	radio.play_index(radio.current_index)
