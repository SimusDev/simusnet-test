extends Node
class_name CT_ObjectHandler

var _registry: Dictionary[StringName, Object] = {}

@onready var _logger: SD_Logger = SD_Logger.new(self)

static var _handlers: Array[CT_ObjectHandler] = []

const GROUP_DEFAULT: StringName = "game"

static func get_handlers() -> Array[CT_ObjectHandler]:
	return _handlers

func _enter_tree() -> void:
	_handlers.append(self)

func _exit_tree() -> void:
	_handlers.erase(self)

func register(id: StringName, object: Object, group: StringName = GROUP_DEFAULT) -> Object:
	id = group + ":" + id
	
	if _registry.has(id):
		_logger.debug("is already registered!: %s, %s" % [id, _logger.variant_to_string(object)], SD_ConsoleCategories.ERROR)
		return self
	
	SD_Nodes.call_method_if_exists(object, "_registered")
	
	_logger.debug("registered: %s, %s" % [id, _logger.variant_to_string(object)])
	return object

func unregister(id: StringName) -> Object:
	var object: Object = _registry.get(id)
	if !object:
		_logger.debug("cant find id!: %s" % [id], SD_ConsoleCategories.ERROR)
		return
	
	SD_Nodes.call_method_if_exists(object, "_unregistered")
	return object
