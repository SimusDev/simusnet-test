extends R_InteractAction

func _server_selected_world(object: Node3D, raycast: CT_InteractionRay) -> void:
	var inventory: CT_Inventory = CT_Inventory.find_in(raycast.root)
	if inventory:
		inventory.try_pickup(object)

func _server_selected_itemstack(item: CT_ItemStack) -> void:
	pass
