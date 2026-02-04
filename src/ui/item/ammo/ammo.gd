@tool
extends Button

@export var ref: R_Ammo

var _item: W_WeaponFirearm
var _stack: CT_ItemStack

func update() -> void:
	if !ref:
		return
	
	icon = ref.get_icon()
	text = ref.id
	
	if !is_instance_valid(_item):
		return
	
	_stack = _item._get_stack()
	if !_stack:
		return
	
	_update_itemstack()

func _update_itemstack() -> void:
	pass
