extends Node
class_name CT_GameScriptHandler

@onready var _logger: SD_Logger = SD_Logger.new(self)
@export_dir var directory: String

var _registry: Dictionary[String, CT_GameScript] = {}

signal on_script_ready(script: CT_GameScript)

func _ready() -> void:
	for i in SD_FileSystem.get_all_files_with_extension_from_directory(directory, SD_FileExtensions.EC_SCRIPT):
		var resource: Resource = load(i)
		if resource is Script:
			if SD_ECS.find_base_script(resource) == CT_GameScript:
				var script: Node = resource.new()
				var id: String = resource.resource_path.get_basename().replacen(directory, "")
				if id.begins_with("/"):
					id = id.erase(0)
				if _registry.has(id):
					id += "_"
				_registry[id] = script
				add_child(script)
				script._initialize()
				script.name = id.validate_node_name()
				_logger.debug("GameScript Ready: %s" % id)

func _exit_tree() -> void:
	for id in _registry:
		_logger.debug("GameScript Delete: %s" % id)
