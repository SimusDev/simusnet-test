extends Resource
class_name R_Object

@export var id: StringName

static var _groups: PackedStringArray = []
static var _objects: Dictionary[String, R_Object]

static func get_list() -> Array[R_Object]:
	return _objects.values()

static func find_by_id(value: String) -> R_Object:
	return _objects.get(value)

static func get_group() -> String:
	return "object"

static func get_group_list() -> PackedStringArray:
	return _groups

func _registered() -> void:
	_objects[id] = self
	if !_groups.has(get_group()):
		_groups.append(get_group())

func _unregistered() -> void:
	_objects.erase(id)
