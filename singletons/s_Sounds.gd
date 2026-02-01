extends Node

@onready var _logger: SD_Logger = SD_Logger.new(self)

func _ready() -> void:
	SimusNetRPC.register(
		[
			_server_play_rpc
		], 
		SimusNetRPCConfig.new()
		.flag_set_channel(Network.CHANNEL_ENVIRONMENT)
		.flag_serialization()
		.flag_mode_server_only()
	)

func server_try_play(resource: R_SoundObject, from: Variant, properties: Dictionary[StringName, Variant], exclude_peers: PackedInt32Array = []) -> void:
	if !SimusNetConnection.is_server():
		_logger.debug("server_try_play(), only server can play sounds!: %s" % resource, SD_ConsoleCategories.ERROR)
		return
	
	if !resource.package:
		_logger.debug("cant server play, package property is null!: %s" % resource, SD_ConsoleCategories.ERROR)
		return
	
	for pid in SimusNetConnection.get_connected_peers():
		if pid in exclude_peers:
			continue
		SimusNetRPC.invoke_on(pid, _server_play_rpc, resource, from, properties)
		
	
	
	#for playable in CT_Playable.get_list():
		#var peer: int = playable.get_peer_id()
		#if SD_SoundInstance3D.is_instance_can_be_created_in_world(resource.package, LevelInstance.get_global_position_from(playable.node)):
			#SimusNetRPC.invoke_on(peer, _server_play_rpc, resource, from, properties)

func _server_play_rpc(resource: R_SoundObject, from: Variant, properties: Dictionary) -> void:
	if SimusNetConnection.is_client():
		if !resource.package:
			_logger.debug("cant server play, package property is null!: %s" % resource, SD_ConsoleCategories.ERROR)
			return
		
		if not SD_SoundInstance3D.is_instance_can_be_created_in_world(resource.package, LevelInstance.get_global_position_from(from)):
			return
		
		var position: Vector3 = LevelInstance.get_global_position_from(from)
		
		var sound: SD_SoundInstance3D = SD_SoundInstance3D.new()
		sound.package = resource.package
		sound.on_play_finish.connect(sound.queue_free)
		sound.instance_autoplay = true
		
		if from is Node:
			from.add_child(sound)
		else:
			add_child(sound)
			sound.global_position = position
		
