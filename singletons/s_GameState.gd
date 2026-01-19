extends Node

@onready var _sd_node_console_commands: SD_NodeConsoleCommands = $SD_NodeConsoleCommands

const BASE_PATH: String = "user://saves"

var _resource: R_GameState = R_GameState.new()

var _runtime_instances: Dictionary[String, R_GameStateNodeInstance]

signal on_begin_save()
signal on_load()

func _normalize_runtime_instances() -> void:
	var id: int = 0
	for i in _runtime_instances:
		if !_runtime_instances[i].is_valid():
			_runtime_instances.erase(i)

func get_resource() -> R_GameState:
	return _resource

func _ready() -> void:
	for cmd in _sd_node_console_commands.commands:
		cmd.source.help_set("<save name>")

func _on_sd_node_console_commands_on_executed(command: SD_ConsoleCommand) -> void:
	match command.get_code():
		"save":
			if command.get_arguments().size() >= 1:
				save_game(command.get_value_as_string())
		"load":
			if command.get_arguments().size() >= 1:
				load_game(command.get_value_as_string())

func _register_instance(node: Node) -> R_GameStateNodeInstance:
	var instance: R_GameStateNodeInstance = _runtime_instances.get_or_add(str(node.get_path()), R_GameStateNodeInstance.new())
	instance.instance = node
	instance.unique_id = str(node.get_path())
	return instance

func save_game(save: String) -> void:
	if !SimusNetConnection.is_server():
		return
	
	_normalize_runtime_instances()
	on_begin_save.emit()
	_resource = R_GameState.new()
	_resource._instances = _runtime_instances.duplicate()
	
	var path: String = SD_FileSystem.normalize_path(BASE_PATH).path_join(save) + ".tres"
	SD_FileSystem.make_directory(BASE_PATH)
	ResourceSaver.save(_resource, path)

func load_game(save: String) -> void:
	if !SimusNetConnection.is_server():
		return
	
	var path: String = SD_FileSystem.normalize_path(BASE_PATH).path_join(save) + ".tres"
	SD_FileSystem.make_directory(BASE_PATH)
	_resource = ResourceLoader.load(path)
	if !_resource:
		return
	
	_runtime_instances = _resource._instances
	for npath in _runtime_instances:
		var node: Node = get_node_or_null(npath)
		if node:
			_register_instance(node)
	
	on_load.emit()
