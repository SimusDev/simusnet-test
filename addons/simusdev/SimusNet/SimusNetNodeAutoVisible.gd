@tool
extends SimusNetNode
class_name SimusNetNodeAutoVisible

enum BROADCAST_TO {
	TO_SERVER,
	TO_ALL,
}

@export var node: Node
@export var broadcast_to: BROADCAST_TO = BROADCAST_TO.TO_SERVER

const _META_NAME: StringName = "SimusNetNodeAutoVisible"

var _peers: PackedInt32Array = []

func get_peers() -> PackedInt32Array:
	return _peers

static func _create(target: Node) -> SimusNetNodeAutoVisible:
	var visibile := SimusNetNodeAutoVisible.new()
	visibile.name = "SimusNetNodeAutoVisible"
	visibile.node = target
	target.set_meta(_META_NAME, visibile)
	return visibile

static func find_in(node: Node) -> SimusNetNodeAutoVisible:
	if node.has_meta(_META_NAME):
		return node.get_meta(_META_NAME)
	return null

static func register_or_get(target: Node, deferred: bool = false) -> SimusNetNodeAutoVisible:
	var founded: SimusNetNodeAutoVisible = find_in(target)
	if founded:
		return founded
	
	var visible: SimusNetNodeAutoVisible = _create(target)
	if deferred:
		target.add_child.call_deferred(visible)
	else:
		target.add_child(visible)
	return visible
	

func _ready() -> void:
	super()
	
	if !node:
		if owner:
			node = owner
		else:
			node = get_parent()
	
	if Engine.is_editor_hint():
		return
	
	node.set_meta(_META_NAME, self)
	
	_peers.append(SimusNetConnection.SERVER_ID)
	
	SimusNetVisibility.set_public_visibility(node, false)
	
	SimusNetEvents.event_peer_disconnected.listen(_on_peer_disconnected, true)
	

func _on_peer_disconnected(event: SimusNetEvent) -> void:
	_peers.erase(event.get_arguments())
	SimusNetVisibility.set_visible_for(event.get_arguments(), node, false)
	

func _send_visible() -> void:
	var peer: int = multiplayer.get_remote_sender_id()
	if !_peers.has(peer):
		_peers.append(peer)
	
	#print(_peers)
	SimusNetVisibility.set_visible_for(peer, node, true)
	#print(node, " is visible for %s" % peer)

func _send_not_visible() -> void:
	var peer: int = multiplayer.get_remote_sender_id()
	_peers.erase(peer)
	SimusNetVisibility.set_visible_for(peer, node, false)
	#print(_peers)
	#print(node, " is not visible for %s" % peer)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	
	if broadcast_to == BROADCAST_TO.TO_SERVER:
		SimusNetRPCGodot.invoke_on_server(_send_not_visible)
		return
	SimusNetRPCGodot.invoke(_send_not_visible)

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	
	if !is_node_ready():
		SimusNetRPCGodot.register_any_peer_reliable([
			_send_visible,
			_send_not_visible,
		], SimusNetChannels.BUILTIN.VISIBILITY)
		SimusNetVisibility.set_method_always_visible(
			[_send_visible, _send_not_visible, ]
		)
	
	if !is_network_ready:
		await on_network_ready
		
	if broadcast_to == BROADCAST_TO.TO_SERVER:
		SimusNetRPCGodot.invoke_on_server(_send_visible)
		
		return
	SimusNetRPCGodot.invoke(_send_visible)

func _network_ready() -> void:
	super()
	_enter_tree()

func _network_disconnect() -> void:
	super()

func _network_not_connected() -> void:
	super()
