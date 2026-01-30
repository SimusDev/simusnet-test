extends CT_ItemStack
class_name CT_ItemStackFireArmWeapon

@export var bullets: int = 0

var _firearm: R_WeaponFirearm

func _ready() -> void:
	super()
	
	_firearm = object
	
	SimusNetVars.register(self, 
	["bullets"],
	_network_var_config
	)
	
	bullets = _firearm.ammo_max

func serialize_gamestate_custom(data: Dictionary) -> void:
	data.farmwpn = s_GameState.serialize_object_properties(self, [
		"bullets",
	])
	

static func deserialize_gamestate_custom(data: Dictionary, stack: CT_ItemStack) -> void:
	s_GameState.deserialize_object_properties(stack, data.farmwpn)

func can_reload() -> bool:
	return bullets < _firearm.ammo_max

func try_reload() -> bool:
	var success: bool = false
	if SimusNetConnection.is_server():
		for item in get_inventory().get_item_stacks():
			if item.object == _firearm.ammo:
				while item.quantity > 0:
					bullets += 1
					item.quantity -= 1
					success = true
					if bullets >= _firearm.ammo_max:
						
						break
	return success
