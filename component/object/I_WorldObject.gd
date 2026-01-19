extends RefCounted
class_name I_WorldObject

var _level: LevelInstance
var _object: R_WorldObject

var _instance: Node3D

const META: StringName = &"I_WorldObject"

func get_object() -> R_WorldObject:
	return _object

func get_level() -> LevelInstance:
	return _level

func get_instance() -> Node3D:
	return _instance

func _init(level: LevelInstance, object: R_WorldObject) -> void:
	_level = level
	_object = object
	
	if !object:
		_level._logger.debug("I_WorldObject: _init(), R_WorldObject is null!", SD_ConsoleCategories.ERROR)

func _validate_prefab() -> PackedScene:
	var prefab: PackedScene = _object.viewmodel.world
	if !prefab:
		_level._logger.debug("%s: viewmodel.world prefab is null!" % _object)
	return prefab 

func _create_instance() -> void:
	var prefab: PackedScene = _validate_prefab()
	if !is_instance_valid(_instance):
		_instance = prefab.instantiate()
		_instance.set_meta(META, self)

func is_inside_tree() -> bool:
	if is_instance_valid(_instance):
		return _instance.is_inside_tree()
	return false

func instantiate_local() -> I_WorldObject:
	_create_instance()
	if !is_inside_tree():
		_level.get_local_group(_object.get_group()).add_child(_instance)
	return self

func instantiate() -> I_WorldObject:
	if not SimusNetConnection.is_server():
		_level._logger.debug("only server can instantiate world object globally.", SD_ConsoleCategories.ERROR)
		return self
	
	_create_instance()
	if !is_inside_tree():
		_level.get_networked_group(_object.get_group()).add_child(_instance)
	return self

func serialize() -> Dictionary:
	var result: Dictionary = {}
	result[0] = SimusNetSerializer.parse(get_object())
	return result

static func deserialize(data: Dictionary, object: Object, level: LevelInstance) -> I_WorldObject:
	var instance: I_WorldObject = I_WorldObject.new(level, SimusNetDeserializer.parse(data[0]))
	instance._instance = object
	instance._instance.set_meta(META, instance)
	return instance

static func find_in(node: Node) -> I_WorldObject:
	if node.has_meta(META):
		return node.get_meta(META)
	return null
