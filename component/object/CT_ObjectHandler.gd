extends Node
class_name CT_ObjectHandler

var _registry: Dictionary[String, Object] = {}

@onready var _logger: SD_Logger = SD_Logger.new(self)

signal on_registered(object: Object, id: String)
signal on_unregistered(object: Object, id: String)

func register(id: String, object: Object) -> bool:
	
	if _registry.has(id):
		_logger.debug("is already registered!: %s, %s" % [id, _logger.variant_to_string(object)], SD_ConsoleCategories.ERROR)
		return false
	
	SD_Nodes.call_method_if_exists(object, "_registered")
	
	_registry[id] = object
	on_registered.emit(object, id)
	_logger.debug("registered: %s, %s" % [id, _logger.variant_to_string(object)])
	return true

func unregister(id: String) -> bool:
	var object: Object = _registry.get(id)
	if !object:
		_logger.debug("cant find id!: %s" % [id], SD_ConsoleCategories.ERROR)
		return false
	
	SD_Nodes.call_method_if_exists(object, "_unregistered")
	_registry.erase(id)
	on_unregistered.emit(object, id)
	return true

func async_load_directory(path: String) -> void:
	for file in SD_FileSystem.get_all_files_with_extension_from_directory(path, SD_FileExtensions.EC_RESOURCE):
		var resource: Resource = load(file)
		if resource is R_Object:
			var id: String = resource.id
			if id.is_empty():
				id = resource.resource_path.get_file().get_basename()
			
			id = resource.get_group() + ":" + id
			
			register(id, resource)
	
	await get_tree().physics_frame
