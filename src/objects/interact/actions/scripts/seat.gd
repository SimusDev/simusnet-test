extends R_InteractAction

func _server_selected_itemstack(item: CT_ItemStack) -> void:
	pass

func _server_selected_world(object: Node3D, raycast: CT_InteractionRay) -> void:
	var seat: CT_Seat = SD_ECS.find_first_component_by_script(object, [CT_Seat])
	if seat:
		seat._try_interact_server(raycast.root)
