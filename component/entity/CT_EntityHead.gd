extends Node
class_name CT_EntityHead

@export var _entity: Node3D
@export var _eyes: Node3D

var _logger: SD_Logger = SD_Logger.new(self)

func _ready() -> void:
	if !_entity:
		_logger.debug("please, set the entity reference.", SD_ConsoleCategories.ERROR)
	
	if !_eyes:
		_logger.debug("please, set the eyes reference.", SD_ConsoleCategories.ERROR)
	
	if _entity:
		SD_ECS.append_to(_entity, self)

func get_entity() -> Node3D:
	return _entity

func get_eyes() -> Node3D:
	return _eyes

static func find_above(from: Node) -> CT_EntityHead:
	return SD_ECS.node_find_above_by_component(from, CT_EntityHead)
