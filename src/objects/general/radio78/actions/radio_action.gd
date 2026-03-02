class_name R_RadioAction extends R_InteractAction

var radio:CT_Radio

func _server_selected_world(object: Node3D, raycast: CT_InteractionRay) -> void:
	radio = CT_Radio.find_above(object)
