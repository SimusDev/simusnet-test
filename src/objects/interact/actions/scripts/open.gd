extends R_InteractAction

func _server_selected_world(object: Node3D, raycast: CT_InteractionRay) -> void:
	var inventory: CT_Inventory = CT_Inventory.find_in(raycast.root)
	var object_inventory: CT_Inventory = CT_Inventory.find_in(object)
	
	if inventory and object_inventory:
		inventory.open(object_inventory)

func _server_selected_itemstack(item: CT_ItemStack) -> void:
	pass
