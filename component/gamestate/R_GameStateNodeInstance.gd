extends Resource
class_name R_GameStateNodeInstance

var instance: Node
var unique_id: String = ""

func is_valid() -> bool:
	return is_instance_valid(instance)

@export var _data: Dictionary = {}

func write(key: Variant, value: Variant) -> R_GameStateNodeInstance:
	_data.set(key, value)
	return self

func read(key: Variant, defualt: Variant = null) -> Variant:
	return _data.get(key, defualt)

func is_data_empty() -> bool:
	return _data.is_empty()
