extends SimusNetSingletonChild
class_name SimusNetVisibility

static var _queue_create: Array[SimusNetIdentity] = []
static var _queue_delete: Array[SimusNetIdentity] = []

static var _instance: SimusNetVisibility

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

static func _local_identity_create(identity: SimusNetIdentity) -> void:
	_queue_create.append(identity)

static func _local_identity_delete(identity: SimusNetIdentity) -> void:
	_queue_delete.append(identity)

static func _serialize_array(array: Array[SimusNetIdentity]) -> void:
	pass

static func _deserialize_array(array: Array[PackedByteArray]) -> void:
	pass

static func set_public_visibility(object: Object, visibility: bool) -> SimusNetVisibility:
	SimusNetVisible.get_or_create(object).set_public_visibility(visibility)
	return _instance

static func set_visible_for(peer: int, object: Object, visible: bool) -> SimusNetVisibility:
	SimusNetVisible.get_or_create(object).set_visible_for(peer, visible)
	return _instance

static func is_public_visible(object: Object) -> bool:
	return SimusNetVisible.get_or_create(object).is_public_visible()

static func get_peers_from(object: Object) -> PackedInt32Array:
	return SimusNetVisible.get_or_create(object).get_peers()

static func is_visible_for(peer: int, object: Object) -> bool:
	return SimusNetVisible.get_or_create(object).is_visible_for(peer)

static func is_method_always_visible(callable: Callable) -> bool:
	return SimusNetVisible.get_or_create(callable.get_object()).is_method_always_visible(callable)

static func set_method_always_visible(callables: Array[Callable], visibility: bool = true) -> SimusNetVisibility:
	for i in callables:
		SimusNetVisible.get_or_create(i.get_object()).set_method_always_visible([i], visibility)
	return _instance
