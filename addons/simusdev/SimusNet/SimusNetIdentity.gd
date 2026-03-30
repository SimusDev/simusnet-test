extends Resource
class_name SimusNetIdentity

var owner: Object : get = get_owner

func get_owner() -> Object:
	if !_owner_weak_ref or !is_instance_valid(_owner_weak_ref.get_ref()):
		return null
	
	return _owner_weak_ref.get_ref()

var _owner_weak_ref: WeakRef

var settings: SimusNetIdentitySettings

signal on_ready()

var is_ready: bool = false

var is_initialized: bool = false

var _generated_unique_id: Variant
var _unique_id: int = -1

var _net_settings: SimusNetSettings

const BYTE_SIZE: int = 2

static func __register__(object: Object, network_id: int, generated_id: Variant) -> SimusNetIdentity:
	if object.has_meta("SimusNetIdentity"):
		var variant: Variant = object.get_meta("SimusNetIdentity")
		if is_instance_valid(variant):
			if variant is SimusNetIdentity:
				if variant.owner == object:
					return variant
	
	var identity: SimusNetIdentity = SimusNetIdentity.new()
	identity.settings = SimusNetIdentitySettings.new()
	identity._generated_unique_id = generated_id
	identity._unique_id = network_id
	
	object.set_meta("SimusNetIdentity", identity)
	
	identity._owner_weak_ref = weakref(object)
	
	identity._initialize()
	return identity

static func register(object: Object, network_id: int = -1) -> SimusNetIdentity:
	return __register__(object, network_id, null)

static func register_with_generated_id(object: Object, id: Variant = null) -> SimusNetIdentity:
	return __register__(object, -1, id)

func _initialize() -> void:
	if !is_instance_valid(settings):
		settings = SimusNetIdentitySettings.new()
	
	SimusNetEvents.event_disconnected.listen(_deinitialize_dynamic)
	
	_net_settings = SimusNetSettings.get_or_create()
	
	if owner is Node:
		if !owner.is_node_ready():
			await owner.ready
		
		owner.renamed.connect(_renamed)
		owner.tree_entered.connect(_tree_entered)
		owner.tree_exiting.connect(_tree_exited)
	
	_initialize_dynamic()
	

static func generate_instance_unique_id_int() -> int:
	return SimusNetIdentitySettings._generate_instance_int()

func _renamed() -> void:
	get_dictionary_by_generated_id().erase(get_generated_unique_id())
	_try_generate_generated_id()
	get_dictionary_by_generated_id().set(get_generated_unique_id(), self)

func _initialize_dynamic() -> void:
	if !SimusNetConnection.is_active():
		await SimusNetEvents.event_connected.published
	
	if SimusNetConnection.is_server():
		if _unique_id == -1:
			_unique_id = SimusNetIdentitySettings._generate_instance_int()
	
	if is_initialized and _unique_id > -1:
		return
	
	is_initialized = true
	
	if SimusNetConnection.is_server():
		_tree_entered()
	else:
		_tree_entered()
		
		if _unique_id == -1:
			SimusNetCache.request_unique_id(get_generated_unique_id())
			SimusNetCache.instance.on_unique_id_received.connect(_on_unique_id_received.bind(get_generated_unique_id()))
			return
		
		_set_ready()

func _on_unique_id_received(generated_id: Variant, unique_id: Variant, requested_id: Variant) -> void:
	if generated_id == requested_id:
		_unique_id = unique_id
		_set_ready()
		SimusNetCache.instance.on_unique_id_received.disconnect(_on_unique_id_received)

func _deinitialize_dynamic() -> void:
	if !is_initialized:
		return
	
	_unique_id = -1
	is_initialized = false
	is_ready = false
	_initialize_dynamic()

func _tree_entered() -> void:
	_try_generate_generated_id()
	get_dictionary_by_generated_id().set(get_generated_unique_id(), self)
	
	if SimusNetConnection.is_server():
		_set_ready()
	

func _try_generate_generated_id() -> void:
	if settings.get_unique_id() == null:
		if owner is Node:
			if !owner.is_node_ready():
				await owner.ready
			
			if !owner.get_path().is_empty():
				_generated_unique_id = owner.get_path()
	else:
		_generated_unique_id = settings.get_unique_id()
	
	

func _set_ready() -> void:
	if is_ready:
		return
	
	_try_generate_generated_id()
	
	get_dictionary_by_unique_id()[get_unique_id()] = self
	get_dictionary_by_generated_id()[get_generated_unique_id()] = self
	
	#if SimusNetConnection.is_server():
		#print("caching: ", get_generated_unique_id())
		#print(get_dictionary_by_generated_id().has(get_generated_unique_id()))
	#
	is_ready = true
	on_ready.emit()
	
	if owner:
		SimusNetVisibility._local_identity_create(self)

func _tree_exited() -> void:
	is_initialized = false
	
	get_dictionary_by_generated_id().erase(get_generated_unique_id())
	#if SimusNetConnection.is_server():
		#print("removing: ", get_generated_unique_id())
	
	SimusNetVisibility._local_identity_delete(self)
	

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		SimusNetVisibility._local_identity_delete(self)

func get_generated_unique_id() -> Variant:
	return _generated_unique_id

func get_unique_id() -> int:
	return _unique_id

func try_serialize_into_variant() -> Variant:
	if get_unique_id() >= 0:
		return get_unique_id()
	return get_generated_unique_id()

static func try_deserialize_from_variant(variant: Variant) -> SimusNetIdentity:
	if variant is int:
		return get_dictionary_by_unique_id().get(variant)
	return get_dictionary_by_generated_id().get(variant)

static func get_dictionary_by_generated_id() -> Dictionary[Variant, SimusNetIdentity]:
	return SimusNetCache.instance._identities_by_generated_id

static func get_dictionary_by_unique_id() -> Dictionary[int, SimusNetIdentity]:
	return SimusNetCache.instance._identities_by_unique_id

static func server_serialize_instance(_owner: Object) -> Variant:
	if SimusNetConnection.is_server():
		var identity: SimusNetIdentity = SimusNetIdentity.register(_owner)
		return identity.get_unique_id()
	return null

static func client_deserialize_instance(data: Variant, _owner: Object) -> SimusNetIdentity:
	var identity := SimusNetIdentity.new()
	identity._unique_id = data
	identity.owner = _owner
	_owner.set_meta("SimusNetIdentity", identity)
	identity._initialize()
	return identity

static func deserialize_unique_id(bytes: PackedByteArray) -> SimusNetIdentity:
	return get_dictionary_by_unique_id().get(deserialize_unique_id_into_int(bytes))

static func deserialize_unique_id_into_int(bytes: PackedByteArray) -> int:
	return bytes.decode_u16(0)

static func try_find_in(object: Variant) -> SimusNetIdentity:
	if object is Object:
		if object.has_meta("SimusNetIdentity"):
			var i: SimusNetIdentity = object.get_meta("SimusNetIdentity")
			if i.owner:
				return i 
	return null
