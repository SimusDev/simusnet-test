extends CT_InventorySlot
class_name CT_InventorySlotCloth

@export var type: R_ClothType

func can_handle_item(item: CT_ItemStack) -> bool:
	if item.object is R_Cloth:
		if not type:
			return true
		return item.type == type
	return false
