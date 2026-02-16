extends Resource
class_name SimusNetIdentity

var owner: Object : get = get_owner

func get_owner() -> Object:
	if !is_instance_valid(owner):
		owner = null
	return owner

var settings: SimusNetIdentitySettings

signal on_ready()

var is_ready: bool = false

var is_initialized: bool = false

var _generated_unique_id: Variant
var _unique_id: int = -1

var _net_settings: SimusNetSettings

const BYTE_SIZE: int = 2

static func register(object: Object, settings: SimusNetIdentitySettings = null, from: SimusNetIdentity = null) -> SimusNetIdentity:
	if object.has_meta("SimusNetIdentity"):
		var variant: Variant = object.get_meta("SimusNetIdentity")
		if is_instance_valid(variant):
			if variant is SimusNetIdentity:
				if variant.owner:
					return variant
	
	var identity: SimusNetIdentity = from
	if !identity:
		identity = SimusNetIdentity.new()
	
	object.set_meta("SimusNetIdentity", identity)
	
	identity.owner = object
	identity.settings = settings
	
	identity._initialize()
	return identity

func _initialize() -> void:
	if !is_instance_valid(settings):
		settings = SimusNetIdentitySettings.new()
	
	SimusNetEvents.event_disconnected.listen(_deinitialize_dynamic)
	
	_net_settings = SimusNetSettings.get_or_create()
	
	if SimusNetConnection.is_server():
		_unique_id = SimusNetIdentitySettings._generate_instance_int()
	
	if owner is Node:
		if !owner.is_node_ready():
			await owner.ready
		
		owner.tree_entered.connect(_tree_entered)
		owner.tree_exited.connect(_tree_exited)
	
	_initialize_dynamic()
	

func _initialize_dynamic() -> void:
	if owner is Node:
		if !owner.is_inside_tree():
			await owner.tree_entered
			_try_generate_generated_id()
	
	if !SimusNetConnection.is_active():
		await SimusNetEvents.event_connected.published
	
	if is_initialized:
		return
	
	is_initialized = true
	
	if SimusNetConnection.is_server():
		_tree_entered()
	else:
		_tree_entered()
		
		if _unique_id == -1:
			SimusNetCache.request_unique_id(get_generated_unique_id())
			SimusNetCache.instance.on_unique_id_received.connect(_on_unique_id_received)
			return
		
		_set_ready()

func _on_unique_id_received(generated_id: Variant, unique_id: Variant) -> void:
	if generated_id == get_generated_unique_id():
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
	
	if SimusNetConnection.is_server():
		_set_ready()
	

func _try_generate_generated_id() -> void:
	if settings.get_unique_id() == null:
		if owner is Node:
			_generated_unique_id = owner.get_path()
			if !owner.is_node_ready():
				await owner.ready
	else:
		_generated_unique_id = settings.get_unique_id()
	
	get_dictionary_by_generated_id()[get_generated_unique_id()] = self

func _set_ready() -> void:
	if is_ready:
		return
	
	_try_generate_generated_id()
	
	get_dictionary_by_unique_id()[get_unique_id()] = self
	#get_dictionary_by_generated_id()[get_generated_unique_id()] = self
	
	is_ready = true
	on_ready.emit()
	
	if owner:
		SimusNetVisibility._local_identity_create(self)

func _tree_exited() -> void:
	if !is_ready:
		await is_ready
	
	_destroy()

static func _parse_and_clear_identities_with_no_owner() -> void:
	var i: Dictionary[int, SimusNetIdentity] = get_dictionary_by_unique_id()
	for id: int in i:
		var identity: SimusNetIdentity = i[id]
		if !identity.owner:
			i.erase(id)
			get_dictionary_by_generated_id().erase(identity.get_generated_unique_id())

func _destroy() -> void:
	if owner:
		SimusNetVisibility._local_identity_delete(self)
	
	_parse_and_clear_identities_with_no_owner()
	

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
			return object.get_meta("SimusNetIdentity")
	return null
