class_name LevelHandler extends Node

signal level_changed

@export var base_path:String = "res://"
@export var directories:PackedStringArray
@export var level_holder:Node

var _registry: Array[R_Level]
var current_level:R_Level

func _ready() -> void:
	SimusNetIdentity.register(self)
	
	SimusNetRPC.register(
		[
			_client_receive_level
		], SimusNetRPCConfig.new().flag_mode_server_only().flag_serialization()
	)
	
	_handle()
	
	for resource in _registry:
		if SimusNetConnection.is_server():
			var level_instance: LevelInstance = LevelInstance._create(resource)
			level_instance._handler = self
			level_holder.add_child(level_instance)

func _player_entered(playable: CT_Playable, level: LevelInstance) -> void:
	if SimusNetConnection.is_server():
		if playable.get_peer_id() != SimusNet.SERVER_ID:
			SimusNetRPC.invoke_on(playable.get_peer_id(), _client_receive_level, level.get_resource())

func _player_exited(playable: CT_Playable, level: LevelInstance) -> void:
	pass

func _client_receive_level(resource: R_Level) -> void:
	if SimusNetConnection.is_client():
		await SD_Nodes.async_clear_all_children(level_holder)
		var level_instance: LevelInstance = LevelInstance._create(resource)
		level_instance._handler = self
		level_holder.add_child(level_instance)

func _handle() -> void:
	for directory:String in directories:
		for file in SD_FileSystem.get_all_files_with_extension_from_directory(base_path.path_join(directory), SD_FileExtensions.EC_RESOURCE):
			var resource:Resource = load(file)
			if resource is R_Level:
				var status: bool = resource.register()
				if status:
					_registry.append(resource)

func _exit_tree() -> void:
	for level in _registry:
		level.unregister()
		_registry.erase(level)

func clear(safe:bool = true) -> void:
	if safe:
		if not is_instance_valid(level_holder):
			return
	await SD_Nodes.async_clear_all_children(level_holder)

func change_level(to:R_Level) -> void:
	if not is_instance_valid(level_holder):
		return
	await clear(false)
	current_level = to
	if current_level:
		var level_instance: LevelInstance = LevelInstance._create(current_level)
		level_holder.add_child(level_instance)
	level_changed.emit()

func change_level_by_code(level_code:StringName) -> void:
	for ref in R_Level.get_reference_list():
		if ref.code == level_code:
			change_level(ref)
