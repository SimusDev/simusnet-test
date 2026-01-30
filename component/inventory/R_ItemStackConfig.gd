extends Resource
class_name R_ItemStackConfig

@export var stackable: bool = true
@export var stack_size: int = 64

var _item_script: GDScript : set = set_item_script, get = get_item_script

func set_item_script(script: GDScript) -> R_ItemStackConfig:
	_item_script = script
	return self

func get_item_script() -> GDScript:
	if _item_script:
		return _item_script
	return CT_ItemStack
