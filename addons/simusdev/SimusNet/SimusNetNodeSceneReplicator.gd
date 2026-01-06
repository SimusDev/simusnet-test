extends SimusNetNode
class_name SimusNetNodeSceneReplicator

@export var root: Node

@export var property_replicate: Dictionary[String, bool] = {
	"position" : true,
	"rotation" : true,
	"scale" : true,
}

@export var clear_children: bool = true

var _queue: Array[Node] = []

func get_channel() -> int:
	return SimusNetChannels.BUILTIN.SCENE_REPLICATION

func _ready() -> void:
	set_multiplayer_authority(SimusNetConnection.SERVER_ID)
	super()
	
	SimusNetVisibility.set_method_always_visible(
		[_send]
	)
	
	SimusNetRPCGodot.register_authority_reliable(
		[
			_server_spawn,
			_server_despawn,
			_recieve,
		],
		get_channel()
	)
	
	SimusNetRPCGodot.register_any_peer_reliable(
		[
			_send
		],
		get_channel()
	)
	

static func serialize_node(node: Node) -> PackedByteArray:
	var result: Dictionary = {}
	return SimusNetCompressor.parse(result)

static func deserialize_node(bytes: PackedByteArray) -> Node:
	var data: Dictionary = SimusNetDecompressor.parse(bytes)
	return null

static func serialize_nodes(nodes: Array[Node]) -> PackedByteArray:
	var result: Array = []
	for i in nodes:
		result.append(serialize_node(i))
	return SimusNetCompressor.parse(result)

static func deserialize_nodes(bytes: PackedByteArray) -> Array[Node]:
	var data: Array = SimusNetDecompressor.parse(bytes)
	var result: Array[Node] = []
	for i in data:
		result.append(deserialize_node(i))
	return result

static func serialize_custom(node: Node, data: Dictionary) -> void:
	pass

static func deserialize_custom(data: Dictionary, node: Node) -> void:
	pass

func _clear_children() -> void:
	if !clear_children:
		return
	
	for i in root.get_children():
		if i is SimusNetNodeSceneReplicator:
			continue
		i.queue_free()
		await i.tree_exited

func _synchronize() -> void:
	if is_server():
		return
	
	await _clear_children()
	SimusNetRPCGodot.invoke_on_server(_send)

func _send() -> void:
	SimusNetRPCGodot.invoke_on(SimusNetRemote.sender_id, _recieve)

func _recieve() -> void:
	pass

func _server_spawn(scenes: Variant) -> void:
	pass

func _server_despawn(nodes: Variant) -> void:
	pass

func _network_ready() -> void:
	super()
	set_process(is_server())
	if !is_server():
		_synchronize()

func _network_disconnect() -> void:
	super()
	set_process(false)

func _network_not_connected() -> void:
	super()
	set_process(false)
