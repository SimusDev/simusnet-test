@static_unload
extends RefCounted
class_name SimusNetSerializer

static var _instance: WeakRef

static func get_instance() -> SimusNetSerializer:
	return _instance.get_ref()

static var _settings: SimusNetSettings

static var _buffer: StreamPeerBuffer = StreamPeerBuffer.new()

static var _current_blocked_methods: Array[StringName] = []

const ARRAY_SIZE: int = 2

const BLACKLIST: Array[int] = [
	TYPE_INT,
	TYPE_FLOAT,
	TYPE_PACKED_BYTE_ARRAY,
	TYPE_BOOL,
	TYPE_ARRAY,
	TYPE_DICTIONARY,
	TYPE_STRING,
]

static func is_object_has_custom_serialization(object: Object) -> bool:
	if _current_blocked_methods.has(parse_custom.get_method()):
		return false
	
	return object.has_method(SimusNetCustomSerialization.METHOD_SERIALIZE) and \
	object.has_method(SimusNetCustomSerialization.METHOD_DESERIALIZE)

static func _throw_error(...args: Array) -> void:
	if _settings.debug_enable:
		printerr("[YOUR UNIQUE ID: %s] [SimusNetSerializer]: " % SimusNetConnection.get_unique_id())
		printerr(args)

func _init() -> void:
	_settings = SimusNetSettings.get_or_create()

enum TYPE {
	NULL,
	OBJECT,
	RESOURCE,
	RESOURCE_CACHED,
	IMAGE,
	IDENTITY,
	IDENTITY_CACHED,
	NODE,
	ARRAY,
	ARRAY_TYPED,
	DICTIONARY,
	CUSTOM,
	STRING_NAME,
	VAR,
}

static var __class_and_method: Dictionary[StringName, Callable] = {
	#"Resource": parse_resource,
	"Object": parse_object,
	"Array": parse_array,
	"Dictionary": parse_dictionary,
	"StringName": parse_string_name,
}

static var _resource_class_and_method: Dictionary[StringName, Callable] = {
	"Image": parse_image
}

static func parse_null(variant: Variant) -> PackedByteArray:
	_buffer.clear()
	_buffer.put_u8(TYPE.NULL)
	return _buffer.data_array

static func parse(variant: Variant, try: bool = true) -> Variant:
	if !try:
		return variant
	
	var parsed: PackedByteArray
	
	var cls: String
	
	if variant is Object:
		cls = variant.get_class()
	
	var type: int = typeof(variant)

	var type_string: String = type_string(type)
	
	var parsable: bool = false
	for c in __class_and_method:
		if c == cls or c == type_string:
			var callable: Callable = __class_and_method[c]
			if _current_blocked_methods.has(callable.get_method()):
				continue
			
			parsable = true
			parsed = callable.call(variant)
			#if variant is C_ItemStack:
				#print(variant, " : ", parsable, __class_and_method[c])
			return parsed
	
	if BLACKLIST.has(type):
		return variant
	
	return parse_var(variant)

static func parse_custom(variant: Object) -> PackedByteArray:
	var serialization := SimusNetCustomSerialization.new()
	_current_blocked_methods.clear()
	if variant.has_method(SimusNetCustomSerialization.METHOD_SERIALIZE):
		variant.call(SimusNetCustomSerialization.METHOD_SERIALIZE, serialization)
	var script: Script = variant.get_script()
	#SimusNetResources.cache(script)
	var bytes: PackedByteArray = PackedByteArray()
	var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	buffer.data_array = bytes
	buffer.put_u8(TYPE.CUSTOM)
	buffer.put_utf8_string(ResourceUID.path_to_uid(script.resource_path).replacen("uid://", ""))
	buffer.put_data(parse_arguments(serialization._data))
	return buffer.data_array

static func parse_raw_object(variant: Object) -> PackedByteArray:
	var identity: SimusNetIdentity = SimusNetIdentity.try_find_in(variant)
	_buffer.clear()
	_buffer.put_u8(TYPE.OBJECT)
	var id: String = ":" + variant.get_class()
	if variant.get_script():
		id = ResourceUID.path_to_uid(variant.get_script().resource_path)
	
	_buffer.put_utf8_string(id)
	
	if identity:
		_buffer.put_var(identity.get_unique_id())
	else:
		_buffer.put_var(null)
	
	_buffer.put_var(SimusNetNodeSceneReplicator.serialize_object_network_parameters(variant))
	
	return _buffer.data_array

static func parse_object(variant: Object) -> PackedByteArray:
	if is_object_has_custom_serialization(variant):
		return parse_custom(variant)

	if variant is Node:
		return parse_node(variant)
	
	if SimusNetIdentity.try_find_in(variant):
		return parse_identity(variant)
	
	if variant is Resource:
		if !variant.resource_local_to_scene and !variant.resource_path.is_empty():
			return parse_resource(variant)
	
	return parse_raw_object(variant)


static func parse_resource(variant: Resource) -> PackedByteArray:
	if !is_instance_valid(variant):
		return parse_null(variant)
	
	if variant.resource_path.is_empty():
		return parse_object(variant)
	
	var cls: String = variant.get_class()
	if cls in _resource_class_and_method:
		return _resource_class_and_method[cls].call(variant)
	
	var id: int = SimusNetResources.get_unique_id(variant)
	if id > -1:
		_buffer.clear()
		_buffer.put_u8(TYPE.RESOURCE_CACHED)
		_buffer.put_u16(id)
		return _buffer.data_array
	
	_buffer.clear()
	_buffer.put_u8(TYPE.RESOURCE)
	_buffer.put_string(SimusNetResources.get_unique_path(variant))
	
	return _buffer.data_array

static func parse_image(image: Image) -> PackedByteArray:
	return PackedByteArray()
	#var data: Dictionary = image.data
	#data.format = image.get_format()
	#return _create_parsed(TYPE.IMAGE, SimusNetCompressor.parse_if_necessary(data))

static func parse_identity(identity: Object) -> PackedByteArray:
	if identity:
		if !identity is SimusNetIdentity:
			identity = SimusNetIdentity.try_find_in(identity)
	
	if identity is SimusNetIdentity:
		_buffer.clear()
		var i: SimusNetIdentity = identity
		var id: int = i.get_unique_id()
		if i.get_unique_id() > -1 and i.is_ready:
			_buffer.put_u8(TYPE.IDENTITY_CACHED)
			if SimusNetByteUtils.array_pack_uint_dynamic(id).size() > 4:
				_buffer.put_u32(id)
			else:
				_buffer.put_u16(id)
			
			return _buffer.data_array
		
		_buffer.put_u8(TYPE.IDENTITY)
		_buffer.put_var(i.try_serialize_into_variant())
		return _buffer.data_array
	return parse_null(identity)

static func parse_node(node: Node) -> Variant:
	var identity: SimusNetIdentity = SimusNetIdentity.try_find_in(node)
	if identity:
		return parse_identity(identity)
	
	if node.is_inside_tree():
		_buffer.clear()
		_buffer.put_u8(TYPE.NODE)
		_buffer.put_utf8_string(str(node.get_path()))
		return _buffer.data_array
	
	return parse_null(node)

static func parse_array(array: Array) -> PackedByteArray:
	var local_buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	var result: Array = []
	
	for i in array:
		result.append(parse(i))
	
	if !array.is_typed():
		local_buffer.clear()
		local_buffer.put_u8(TYPE.ARRAY)
		local_buffer.put_var(result)
		return local_buffer.data_array
	
	local_buffer.clear()
	local_buffer.put_u8(TYPE.ARRAY_TYPED)
	local_buffer.put_var(result)
	local_buffer.put_u16(array.get_typed_builtin())
	local_buffer.put_utf8_string(array.get_typed_class_name())
	var typed_script: Variant = array.get_typed_script()
	if is_instance_valid(typed_script):
		local_buffer.put_u8(1)
		local_buffer.put_data(parse_resource(typed_script))
	else:
		local_buffer.put_u8(0)

	return local_buffer.data_array

static func parse_dictionary(dictionary: Dictionary) -> PackedByteArray:
	var result: Dictionary = Dictionary({},
	dictionary.get_typed_key_builtin(),
	dictionary.get_typed_key_class_name(),
	dictionary.get_typed_key_script(),
	dictionary.get_typed_value_builtin(),
	dictionary.get_typed_value_class_name(),
	dictionary.get_typed_value_script()
	)
	for key in dictionary:
		result[parse(key)] = parse(dictionary[key])
	
	_buffer.clear()
	_buffer.put_u8(TYPE.DICTIONARY)
	_buffer.put_var(result)
	return _buffer.data_array

static func parse_string_name(string: StringName) -> PackedByteArray:
	_buffer.clear()
	_buffer.put_u8(TYPE.STRING_NAME)
	_buffer.put_var(string)
	return _buffer.data_array

static func parse_arguments(args: Array, serialization: bool = true) -> PackedByteArray:
	if serialization:
		var parsed: Array = []
		for i in args:
			parsed.append(parse(i))
		return SimusNetArguments.serialize(parsed)
	return SimusNetArguments.serialize(args)

static func parse_var(variant: Variant) -> PackedByteArray:
	_buffer.clear()
	_buffer.put_u8(TYPE.VAR)
	_buffer.put_var(variant)
	return _buffer.data_array

static func test() -> void:
	var simusnet_packet: PackedByteArray = SimusNet.serialize_packet(SimusNet.PACKET.RPC_DEFLATE, var_to_bytes(34))
	print(SimusNet.deserialize_packet(simusnet_packet))
	
	var variant: PackedByteArray = SimusNetSerializer.parse_var(Transform3D())
	print("variant: %s bytes" % variant.size())
	print(SimusNetDeserializer.parse(variant))
	
	var resource: PackedByteArray = SimusNetSerializer.parse_resource(SimusNetSingleton.get_instance().get_script())
	print("resource: %s bytes" % resource.size())
	print(SimusNetDeserializer.parse(resource))
	
	var custom: PackedByteArray = SimusNetSerializer.parse_custom(SimusNetSingleton.get_instance())
	print("custom: %s bytes" % custom.size())
	print(SimusNetDeserializer.parse(custom))
	
	var _identity: PackedByteArray = SimusNetSerializer.parse_identity(SimusNetSingleton.get_instance())
	print("identity: %s bytes" % _identity.size())
	print(SimusNetDeserializer.parse(_identity))
	
	var node: PackedByteArray = SimusNetSerializer.parse_node(SimusNetSingleton.get_instance())
	print("node: %s bytes" % node.size())
	print(SimusNetDeserializer.parse(node))
	
	var array_og: Array = [
		123,
		"hello_world",
		load("uid://hso2ju3bqqww"),
	]
	print(array_og)
	var array: PackedByteArray = SimusNetSerializer.parse_array(array_og)
	print("array: %s bytes" % array.size())
	print(SimusNetDeserializer.parse(array))
	
	var dictionary_og: Dictionary = {
		"my_key": "my_value",
		1_000_000: load("uid://hso2ju3bqqww"),
		"flag" : true
	}
	
	print(dictionary_og)
	var dictionary: PackedByteArray = SimusNetSerializer.parse_dictionary(dictionary_og)
	print("dictionary: %s bytes" % dictionary.size())
	print(SimusNetDeserializer.parse(dictionary))
	
	var object: PackedByteArray = SimusNetSerializer.parse_object(SimusNetSettings.new())
	print("object: %s bytes" % object.size())
	print(SimusNetDeserializer.parse(object))
	
	var array_typed_og: Array[SimusNetTestSerializable] = [
		SimusNetTestSerializable.new(),
		SimusNetTestSerializable.new()
	]
	print(array_typed_og)
	var array_typed: PackedByteArray = SimusNetSerializer.parse_array(array_typed_og)
	print("array typed: %s bytes" % array_typed.size())
	var atd: Array[SimusNetTestSerializable] = SimusNetDeserializer.parse(array_typed)
	print(atd)
