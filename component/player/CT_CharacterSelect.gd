extends Node
class_name CT_CharacterSelect

static var _instance: CT_CharacterSelect

func _ready() -> void:
	_instance = self
	
	SimusNetConnection.connect_network_node_callables(self,
	_net_ready,
	_net_disconnect,
	_net_not_connected
	)
	
	SimusNetRPC.register(
		[
			_send_spawn_locations,
			_request_spawn_server,
			
		], SimusNetRPCConfig.new().flag_mode_any_peer()
		.flag_serialization().flag_set_channel(Network.CHANNEL_USERS)
	)
	
	SimusNetRPC.register(
		[
			_receive_spawn_locations
		], SimusNetRPCConfig.new().flag_mode_server_only()
		.flag_serialization().flag_set_channel(Network.CHANNEL_USERS)
	)
	

var _synced_locations: Array[R_LocationPoint] = []
signal _synced_locations_changed()

static func async_get_spawn_locations() -> Array[R_LocationPoint]:
	if SimusNetConnection.is_server():
		var result: Array[R_LocationPoint] = []
		for spawn in CT_SpawnPoint3D.get_list():
			result.append(R_LocationPoint.create_from_spawnpoint(spawn))
		return result
	SimusNetRPC.invoke_on_server(_instance._send_spawn_locations)
	await _instance._synced_locations_changed
	return _instance._synced_locations

func _send_spawn_locations() -> void:
	var result: Array = []
	for spawn in CT_SpawnPoint3D.get_list():
		var location: R_LocationPoint = R_LocationPoint.create_from_spawnpoint(spawn)
		result.append(location.serialize())
	SimusNetRPC.invoke_on_sender(_receive_spawn_locations, result)

func _receive_spawn_locations(locations: Array) -> void:
	_synced_locations.clear()
	for serialized in locations:
		_synced_locations.append(R_LocationPoint.deserialize(serialized))
	_synced_locations_changed.emit()

static func request_spawn(location: R_LocationPoint, player: R_Player) -> void:
	if location and player:
		SimusNetRPC.invoke_on_server(_instance._request_spawn_server, location.serialize(), player)

func _request_spawn_server(location_s: Variant, player: R_Player) -> void:
	var user: CT_User = CT_User.find_by_peer(SimusNetRemote.sender_id)
	if !user:
		return
	
	if user.get_player_node():
		return
	
	var location: R_LocationPoint = R_LocationPoint.deserialize(location_s)
	var spawn: CT_SpawnPoint3D = location.to_spawnpoint(location.level.get_instance())
	var world_object: I_WorldObject = I_WorldObject.new(spawn.get_level(), player)
	var player_node: Node = world_object.create_instance().get_instance()
	player_node.set_multiplayer_authority(SimusNetRemote.sender_id)
	player_node.global_transform = spawn.global_transform
	user.set_in(player_node)
	#print(player_node.get_multiplayer_authority())
	world_object.instantiate()

func _net_ready() -> void:
	if SimusNetConnection.is_server():
		s_Users.on_connected.connect(_on_user_connected)
		s_Users.on_disconnected.connect(_on_user_disconnected)
	
	

func _net_disconnect() -> void:
	if SimusNetConnection.is_was_server():
		s_Users.on_connected.disconnect(_on_user_connected)
		s_Users.on_disconnected.disconnect(_on_user_disconnected)

func _net_not_connected() -> void:
	pass

func _on_user_connected(user: CT_User) -> void:
	pass

func _on_user_disconnected(user: CT_User) -> void:
	pass
