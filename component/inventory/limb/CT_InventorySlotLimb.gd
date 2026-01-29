class_name CT_InventorySlotLimb extends CT_InventorySlot

@export var type:R_Limb.LimbType = R_Limb.LimbType.ARM
@export var side:R_Limb.LimbSide = R_Limb.LimbSide.LEFT

func can_handle_item(item: CT_ItemStack) -> bool:
	return item.object is R_Limb and \
		item.object.type == type and \
		item.object.side == side
