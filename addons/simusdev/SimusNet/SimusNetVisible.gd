extends RefCounted
class_name SimusNetVisible

const _META: StringName = &"SimusNetVisible"

var _object: Object
var _peers: PackedInt32Array = []
var _methods_always_visible: Array[StringName] = []
var _public_visible: bool = true

func is_public_visible() -> bool:
	return _public_visible

func get_object() -> Object:
	return _object

func _initialize() -> void:
	SimusNetEvents.event_peer_disconnected.listen(_on_peer_disconnected, true)

func _on_peer_disconnected(event: SimusNetEvent) -> void:
	_peers.erase(event.get_arguments())

func get_peers() -> PackedInt32Array:
	return _peers

func set_public_visibility(visibility: bool) -> SimusNetVisible:
	_public_visible = visibility
	return self 

func set_visible_for(peer: int, visible: bool) -> SimusNetVisible:
	if visible:
		if !_peers.has(peer):
			_peers.append(peer)
		return
	_peers.erase(peer)
	return self

func is_visible_for(peer: int) -> bool:
	if is_public_visible() or peer == SimusNetConnection.get_unique_id():
		return true
	return _peers.has(peer)

func is_method_always_visible(callable: Callable) -> bool:
	return _methods_always_visible.has(callable.get_method())

func set_method_always_visible(callables: Array[Callable], visibility: bool = true) -> SimusNetVisible:
	for callable in callables:
		if visibility:
			if !_methods_always_visible.has(callable.get_method()):
				_methods_always_visible.append(callable.get_method())
		else:
			_methods_always_visible.erase(callable.get_method())
	return self

static func get_or_create(object: Object) -> SimusNetVisible:
	if object.has_meta(_META):
		return object.get_meta(_META)
	var visible := SimusNetVisible.new()
	visible._object = object
	visible._initialize()
	object.set_meta(_META, visible)
	return visible

static func set_visibile(object: Object, visible: SimusNetVisible) -> void:
	object.set_meta(_META, visible)
