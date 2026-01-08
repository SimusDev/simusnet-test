@icon("./icons/MultiplayerSpawner.svg")
extends SimusNetNode
class_name SimusNetNodeSceneReplicator

@export var root: Node
@export var clear_children: bool = true
@export var optimize_paths: bool = true

@export var replicate_transform: bool = true

var _queue: Array[Node] = []
var _queue_delete: Array[Node] = []

@export var client_replace: Dictionary[PackedScene, PackedScene] = {}

enum KEY {
	SCENE,
	NAME,
	TRANSFORM,
	MULTIPLAYER_AUTHORITY,
}

func get_channel() -> int:
	return SimusNetChannels.BUILTIN.SCENE_REPLICATION

func _ready() -> void:
	super()
	set_multiplayer_authority(SimusNetConnection.SERVER_ID)
	
	SimusNetNodeAutoVisible.register_or_get(self)
	
	SimusNetVisibility.set_method_always_visible(
		[_send, _receive]
	)
	
	SimusNetRPCGodot.register_authority_reliable(
		[
			#_server_spawn,
			#_server_despawn,
			_receive,
		],
		get_channel()
	)
	
	SimusNetRPCGodot.register_any_peer_reliable(
		[
			_send
		],
		get_channel()
	)
	

func can_serialize_node(node: Node) -> bool:
	if node.scene_file_path.is_empty():
		return false
	return true

func serialize_node(node: Node) -> PackedByteArray:
	var result: Dictionary = {}
	result[KEY.SCENE] = SimusNetSerializer.parse_resource(load(node.scene_file_path))
	result[KEY.NAME] = node.name
	
	if "transform" in node:
		result[KEY.TRANSFORM] = node.transform
	
	if node.get_multiplayer_authority() != SimusNet.SERVER_ID:
		result[KEY.MULTIPLAYER_AUTHORITY] = node.get_multiplayer_authority()
	
	return SimusNetCompressor.parse(result)

func scene_deserialized(scene: PackedScene) -> PackedScene:
	return client_replace.get(scene, scene)

func deserialize_node(bytes: PackedByteArray) -> Node:
	var data: Dictionary = SimusNetDecompressor.parse(bytes)
	
	var scene: PackedScene = SimusNetDeserializer.parse_resource(data[KEY.SCENE])
	scene = scene_deserialized(scene)
	
	if SimusNetConnection.is_client():
		scene = client_replace.get(scene, scene)
	
	var node: Node = scene.instantiate()
	node.name = data[KEY.NAME]
	
	if data.has(KEY.TRANSFORM):
		node.transform = data[KEY.TRANSFORM]
	if data.has(KEY.MULTIPLAYER_AUTHORITY):
		node.set_multiplayer_authority(data[KEY.MULTIPLAYER_AUTHORITY])
	
	return node

func serialize_nodes(nodes: Array[Node]) -> PackedByteArray:
	var result: Array = []
	for i in nodes:
		if can_serialize_node(i):
			result.append(serialize_node(i))
	return SimusNetCompressor.parse(result)

func deserialize_nodes(bytes: PackedByteArray) -> Array[Node]:
	var data: Array = SimusNetDecompressor.parse(bytes)
	var result: Array[Node] = []
	for i in data:
		result.append(deserialize_node(i))
	return result

func serialize_nodes_to_delete(nodes: Array[Node], _root: Node) -> PackedByteArray:
	var result: Array = []
	for i in nodes:
		result.append(str(_root.get_path_to(i)))
	return SimusNetCompressor.parse(result)

func deserialize_nodes_to_delete(bytes: PackedByteArray, _root: Node) -> Array[Node]:
	var data: Array = SimusNetDecompressor.parse(bytes)
	var result: Array[Node] = []
	for path: String in data:
		var node: Node = _root.get_node(path)
		if node:
			result.append(node)
	return result

func serialize_custom(node: Node, data: Dictionary) -> void:
	pass

func deserialize_custom(data: Dictionary, node: Node) -> void:
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
	SimusNetRPCGodot.invoke_on(multiplayer.get_remote_sender_id(), _receive, serialize_nodes(root.get_children()))

func _receive(packet: Variant) -> void:
	
	var nodes: Array[Node] = deserialize_nodes(packet)
	for i in nodes:
		root.add_child(i)

func _receive_deletion(packet: Variant) -> void:
	var nodes: Array[Node] = deserialize_nodes_to_delete(packet, root)
	for i in nodes:
		i.queue_free()
	

var _child_count: int = 0

func _on_child_entered_tree(node: Node) -> void:
	if !node.is_node_ready():
		await node.ready
	
	node.name = node.name.validate_node_name()
	if optimize_paths:
		node.name = str(_child_count)
		_child_count += 1
	
	_queue.append(node)
	_queue_delete.erase(node)

func _on_child_exiting_tree(node: Node) -> void:
	_queue.erase(node)
	_queue_delete.erase(node)

func _process(delta: float) -> void:
	if !SimusNetConnection.is_server():
		return
	
	if !_queue.is_empty():
		SimusNetRPCGodot.invoke(_receive, serialize_nodes(_queue))
		_queue.clear()
	
	if !_queue_delete.is_empty():
		SimusNetRPCGodot.invoke(_receive_deletion, serialize_nodes_to_delete(_queue_delete, root))
		_queue_delete.clear()

func _network_ready() -> void:
	super()
	
	set_process(is_server())
	
	if SimusNetConnection.is_was_server():
		if optimize_paths:
			for i in root.get_children():
				if i is SimusNetNodeSceneReplicator:
					continue
					
				i.name = str(_child_count)
				_child_count += 1
		
		root.child_entered_tree.connect(_on_child_entered_tree)
		root.child_exiting_tree.connect(_on_child_exiting_tree)
	else:
		_synchronize()

func _network_disconnect() -> void:
	super()
	set_process(false)
	
	if SimusNetConnection.is_was_server():
		root.child_entered_tree.disconnect(_on_child_entered_tree)
		root.child_exiting_tree.disconnect(_on_child_exiting_tree)
	else:
		_clear_children()

func _network_not_connected() -> void:
	super()
	set_process(false)
