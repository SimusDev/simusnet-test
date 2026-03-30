@icon("./icons/MultiplayerSpawner.svg")
extends SimusNetNode
class_name SimusNetNodeSceneReplicator

@export var root: Node
@export var clear_children: bool = true
@export var optimize_paths: bool = true

@export var replicate_transform: bool = true
@export var transfer_mode: MultiplayerPeer.TransferMode = MultiplayerPeer.TransferMode.TRANSFER_MODE_RELIABLE

var _queue: Array[Node] = []
var _queue_delete: Array[String] = []

@export var client_replace: Dictionary[PackedScene, PackedScene] = {}

enum KEY {
	SCENE,
	NAME,
	TRANSFORM,
	MULTIPLAYER_AUTHORITY,
	NETWORK_PARAMETERS,
}

func get_channel() -> int:
	return SimusNetChannels.BUILTIN.SCENE_REPLICATION

func _ready() -> void:
	set_multiplayer_authority(SimusNetConnection.SERVER_ID)
	
	SimusNetVisibility.set_method_always_visible(
		[_send, _receive]
	)
	
	SimusNetRPCGodot.register([_receive, _receive_deletion],
	MultiplayerAPI.RPCMode.RPC_MODE_AUTHORITY, transfer_mode, get_channel())
	
	SimusNetRPCGodot.register([_send],
	MultiplayerAPI.RPCMode.RPC_MODE_ANY_PEER, MultiplayerPeer.TransferMode.TRANSFER_MODE_RELIABLE,
	get_channel())
	
	super()

func can_serialize_node(node: Node) -> bool:
	if node.scene_file_path.is_empty():
		return false
	return true

func serialize_node(node: Node) -> Variant:
	var result: Dictionary = {}
	result[KEY.SCENE] = SimusNetSerializer.parse_resource(load(node.scene_file_path))
	result[KEY.NAME] = node.name
	
	if "transform" in node:
		result[KEY.TRANSFORM] = node.transform
	
	if node.get_multiplayer_authority() != SimusNet.SERVER_ID:
		result[KEY.MULTIPLAYER_AUTHORITY] = node.get_multiplayer_authority()
	
	var network_parameters: Dictionary = serialize_object_network_parameters(node)
	if !network_parameters.is_empty():
		result[KEY.NETWORK_PARAMETERS] = network_parameters
	
	serialize_custom(node, result)
	return SimusNetCompressor.parse_if_necessary(result)

func scene_deserialized(scene: PackedScene) -> PackedScene:
	return client_replace.get(scene, scene)

func deserialize_node(bytes: Variant) -> Node:
	var data: Dictionary = SimusNetDecompressor.parse_if_necessary(bytes)
	
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
	if data.has(KEY.NETWORK_PARAMETERS):
		deserialize_object_network_parameters_to(node, data[KEY.NETWORK_PARAMETERS])
	
	deserialize_custom(data, node)
	return node

func serialize_nodes(nodes: Array[Node]) -> Variant:
	var result: Array = []
	for i in nodes:
		if is_instance_valid(i):
			if can_serialize_node(i):
				result.append(serialize_node(i))
	return SimusNetCompressor.parse_if_necessary(result)

func deserialize_nodes(bytes: Variant) -> Array[Node]:
	var data: Array = SimusNetDecompressor.parse_if_necessary(bytes)
	var result: Array[Node] = []
	for i in data:
		result.append(deserialize_node(i))
	return result

func serialize_nodes_to_delete(nodes: Array[String], _root: Node) -> Variant:
	return SimusNetCompressor.parse_if_necessary(nodes)

func deserialize_nodes_to_delete(bytes: Variant, _root: Node) -> Array[Node]:
	var data: Array = SimusNetDecompressor.parse_if_necessary(bytes)
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
	for child in root.get_children():
		if can_serialize_node(child):
			SimusNetRPCGodot.invoke_on(multiplayer.get_remote_sender_id(), _receive, serialize_nodes([child]))

func _receive(packet: Variant) -> void:
	var nodes: Array[Node] = deserialize_nodes(packet)
	for i in nodes:
		if root.has_node(str(i.name)):
			await root.get_node(str(i.name)).tree_exited
		
		if get_tree():
			await get_tree().process_frame
		
		if root.has_node(str(i.name)):
			i.queue_free()
			continue
		
		root.add_child(i)

func _receive_deletion(packet: Variant) -> void:
	var nodes: Array[Node] = deserialize_nodes_to_delete(packet, root)
	for i in nodes:
		i.queue_free()

var _child_count: int = 0

func clear_path_optimization() -> void:
	_child_count = 0

func _on_child_entered_tree(node: Node) -> void:
	node.name = node.name.validate_node_name()
	if optimize_paths:
		node.name = str(_child_count)
		_child_count += 1
	
	_queue.append(node)

func _on_child_exiting_tree(node: Node) -> void:
	_queue_delete.append(str(root.get_path_to(node)))

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

enum R_KEYS {
	NETWORK_PARAMETERS,
}

static func _replication_parameters_put_identities(object: Object, root: Object, data: Dictionary) -> void:
	var identity: SimusNetIdentity = SimusNetIdentity.try_find_in(object)
	if identity:
		if identity.owner:
			if object is Node:
				var node: Node = object as Node
				var node_paths: Dictionary = data.get_or_add(R_KEYS.NETWORK_PARAMETERS, {})
				var path_dict: Dictionary = node_paths.get_or_add(str(root.get_path_to(node)), {})
				
				path_dict.set("id", identity.get_unique_id())
				
				var vars: Dictionary = {}
				_replication_parameters_put_vars(object, vars)
				
				if !vars.is_empty():
					path_dict.set("vars", vars)
				
				for child in node.get_children():
					_replication_parameters_put_identities(child, root, data)
			
			if !object is Node:
				var dict: Dictionary = data.get_or_add(R_KEYS.NETWORK_PARAMETERS, {})
				dict.set("id", identity.get_unique_id())
				
				var vars: Dictionary = {}
				_replication_parameters_put_vars(object, vars)
				
				if !vars.is_empty():
					dict.set("vars", vars)

static func _replication_parameters_get_vars_from(object: Object) -> PackedStringArray:
	var config: SimusNetVarConfigHandler = SimusNetVarConfigHandler.find_in(object)
	if config:
		return config.get_all_properties()
	return []

static func _replication_parameters_put_vars(object: Object, data: Dictionary) -> void:
	for p: String in _replication_parameters_get_vars_from(object):
		var p_ser: Variant = SimusNetVars.try_serialize_into_variant(p)
		data.set(p_ser, SimusNetSerializer.parse(object.get(p)))

static func _deserialize_object_vars(object: Object, data: Dictionary) -> void:
	for p_ser: Variant in data:
		var p: String = SimusNetVars.try_deserialize_from_variant(p_ser)
		var value: Variant = SimusNetDeserializer.parse(data[p_ser])
		object.set(p, value)

static func serialize_object_network_parameters(object: Object) -> Dictionary:
	var result: Dictionary = {}
	_replication_parameters_put_identities(object, object, result)
	return result

static func deserialize_object_network_parameters_to(object: Object, data: Dictionary) -> void:
	var params: Dictionary = data.get(R_KEYS.NETWORK_PARAMETERS, {})
	if params.is_empty():
		return
	
	if object is Node:
		_deserialize_node_identities(object, object, params)
		return
	
	var id: int = params.get("id")
	SimusNetIdentity.register(object, id)
	_deserialize_object_vars(object, params.get("vars", {}))

static func _deserialize_node_identities(_node: Node, _root: Node, data: Dictionary) -> void:
	for path: String in data:
		var founded: Node = _root.get_node_or_null(path)
		if !founded:
			continue
		
		var node_dict: Dictionary = data[path]
		SimusNetIdentity.register(_node, node_dict.id)
		_deserialize_object_vars(founded, node_dict.get("vars", {}))
