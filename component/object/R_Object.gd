extends Resource
class_name R_Object

@export var id: StringName

@export var icon: Texture : get = get_icon

func get_icon() -> Texture:
	if !icon:
		icon = load("uid://jd2nmbvoduv8")
	return icon

static var _groups: PackedStringArray = []
static var _groups_level: PackedStringArray = []
static var _objects: Dictionary[String, R_Object]

static func get_list() -> Array[R_Object]:
	return _objects.values()

static func find_by_id(value: String) -> R_Object:
	return _objects.get(value)

static func get_group() -> String:
	return "object"

static func is_level_group_supported() -> bool:
	return false

static func get_group_list() -> PackedStringArray:
	return _groups

static func get_level_group_list() -> PackedStringArray:
	return _groups_level

func _registered() -> void:
	_objects[id] = self
	if !_groups.has(get_group()):
		_groups.append(get_group())
	
	if is_level_group_supported():
		if !_groups_level.has(get_group()):
			_groups_level.append(get_group())

func _unregistered() -> void:
	_objects.erase(id)
