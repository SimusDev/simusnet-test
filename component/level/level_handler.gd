class_name LevelHandler extends Node

signal level_changed

@export var base_path:String = "res://"
@export var directories:PackedStringArray
@export var level_holder:Node

var _registry: Array[R_Level]
var current_level:R_Level

var _levels: Dictionary[R_Level, LevelInstance] = {}

func get_levels_dictionary() -> Dictionary[R_Level, LevelInstance]:
	return _levels

func get_level_by_resource(resource: R_Level) -> LevelInstance:
	return _levels.get(resource)

func _ready() -> void:
	SimusNetIdentity.register(self)
	
	SimusNetRPC.register(
		[
			_client_receive_level
		], SimusNetRPCConfig.new().flag_mode_server_only().flag_serialization()
	)
	
	SimusNetRPC.register(
		[
			_request_transition_rpc
		], SimusNetRPCConfig.new().flag_mode_to_server().flag_serialization()
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
	R_Level._reference_list.clear()
	
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

func request_transition_to_level() -> void:
	var player: CT_Playable = CT_Playable.get_local()
	if !player:
		return
	
	SimusNetRPC.invoke_on_server(_request_transition_rpc)

func _request_transition_rpc() -> void:
	var playable: CT_Playable = CT_Playable.get_by_peer_id(SimusNetRemote.sender_id)
	if !playable:
		return
	
	var transition: CT_LevelTransition3D = CT_LevelTransition3D.get_last_from(playable.get_playable_node())
	if is_instance_valid(transition):
		transition.try_teleport_entity(playable.get_playable_node())
