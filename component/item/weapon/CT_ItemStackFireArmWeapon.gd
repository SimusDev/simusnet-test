extends CT_ItemStack
class_name CT_ItemStackFireArmWeapon

@export var bullets: int = 0 :
	set(value):
		bullets = value
		on_bullets_changed.emit()
	
@export var ammo: R_Ammo :
	set(value):
		ammo = value
		on_ammo_changed.emit()

var _firearm: R_WeaponFirearm

var _server_bullets: Array[R_Ammo]

signal on_bullets_changed()
signal on_ammo_changed()

func _ready() -> void:
	super()
	
	_firearm = object
	
	SimusNetVars.register(self, 
	["bullets", "ammo"],
	_network_var_config
	)
	
	var pack: R_AmmoPack = _firearm.ammo_pack
	
	if pack and !pack.list.is_empty():
		if SimusNetConnection.is_server():
			if metadata_get("firearm_init", false) == false:
				bullets = _firearm.ammo_max
				ammo = _firearm.ammo_pack.list.get(0)
				metadata_put_or_get("fire_arm_init", true)

func serialize_gamestate_custom(data: Dictionary) -> void:
	data.farmwpn = s_GameState.serialize_object_properties(self, [
		"bullets",
		"ammo",
	])
	

static func deserialize_gamestate_custom(data: Dictionary, stack: CT_ItemStack) -> void:
	s_GameState.deserialize_object_properties(stack, data.farmwpn)

func can_reload() -> bool:
	return bullets < _firearm.ammo_max

func try_discharge() -> bool:
	var success: bool = false
	
	return success

func try_reload() -> bool:
	var success: bool = false
	if SimusNetConnection.is_server():
		for item in get_inventory().get_item_stacks():
			if item.object == ammo:
				while item.quantity > 0:
					bullets += 1
					item.quantity -= 1
					success = true
					if bullets >= _firearm.ammo_max:
						return success
	return success
