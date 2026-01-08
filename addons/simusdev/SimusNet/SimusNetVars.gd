extends SimusNetSingletonChild
class_name SimusNetVars

const BUILTIN_CACHE: PackedStringArray = [
	"transform",
	"position",
	"rotation",
	"scale",
]

static var _instance: SimusNetVars

static var _event_cached: SimusNetEventVariableCached
static var _event_uncached: SimusNetEventVariableUncached

static func get_cached() -> PackedStringArray:
	return SimusNetCache.data_get_or_add("v", PackedStringArray())

static func get_id(property: String) -> int:
	return get_cached().find(property)

static func get_name_by_id(id: int) -> String:
	return get_cached().get(id)

static func try_serialize_into_variant(property: String) -> Variant:
	var method_id: int = get_id(property)
	if method_id > -1:
		return method_id
	return property

static func try_deserialize_from_variant(variant: Variant) -> String:
	if variant is int:
		return get_cached().get(variant)
	return variant as String

func initialize() -> void:
	_instance = self
	_event_cached = SimusNetEvents.event_variable_cached
	_event_uncached = SimusNetEvents.event_variable_uncached
	
	for p in BUILTIN_CACHE:
		cache(p)

static func cache(property: String) -> void:
	if SimusNetConnection.is_server():
		if get_cached().has(property):
			return
		
		_instance._cache_rpc.rpc(property)

@rpc("authority", "call_local", "reliable", SimusNetChannels.BUILTIN.CACHE)
func _cache_rpc(property: String) -> void:
	get_cached().append(property)
	_event_cached.property = property
	_event_cached.publish()

static func uncache(property: String) -> void:
	if SimusNetConnection.is_server():
		if !get_cached().has(property):
			return
		
		_instance._uncache_rpc.rpc(property)

@rpc("authority", "call_local", "reliable", SimusNetChannels.BUILTIN.CACHE)
func _uncache_rpc(property: String) -> void:
	get_cached().erase(property)
	_event_uncached.property = property
	_event_uncached.publish()
