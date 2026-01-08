extends SimusNetNodeSceneReplicator
class_name SimusNetNodePlayerSpawner

@export var prefabs: Array[PackedScene] = []
@export var spawnpoints: Array[Node] = []

var _players: Dictionary[int, Node] = {}

func pick_prefab() -> PackedScene:
	return prefabs.pick_random()

func pick_spawnpoint() -> Node:
	return spawnpoints.filter(func(node: Node): return is_instance_valid(node)).pick_random()

func _network_disconnect() -> void:
	super()
	
	if SimusNetConnection.is_was_server():
		SimusNetEvents.event_peer_connected.unlisten(_peer_connected_server)
		SimusNetEvents.event_peer_disconnected.unlisten(_peer_disconnected_server)

func _network_not_connected() -> void:
	super()

func _network_ready() -> void:
	super()
	if !SimusNetConnection.is_was_server():
		return
	
	for pid in SimusNetConnection.get_connected_peers_include_self():
		_add_player(pid)
	
	SimusNetEvents.event_peer_connected.listen(_peer_connected_server, true)
	SimusNetEvents.event_peer_disconnected.listen(_peer_disconnected_server, true)

func _add_player(peer: int) -> void:
	var prefab: PackedScene = pick_prefab()
	if !prefab:
		push_error("can't add player, prefab is null!")
		return
	
	var instance: Node = prefab.instantiate()
	instance.set_multiplayer_authority(peer)
	var spawnpoint: Node = pick_spawnpoint()
	root.add_child.call_deferred(instance)
	
	_players[peer] = instance
	
	if spawnpoint:
		if "transform" in spawnpoint and "transform" in instance:
			await instance.tree_entered
			instance.global_transform = spawnpoint.global_transform
	
	
	

func _remove_player(peer: int) -> void:
	var founded: Node = _players.get(peer)
	if is_instance_valid(founded):
		founded.queue_free()
	_players.erase(peer)

func _peer_connected_server(event: SimusNetEvent) -> void:
	_add_player(event.get_arguments())

func _peer_disconnected_server(event: SimusNetEvent) -> void:
	_remove_player(event.get_arguments())
