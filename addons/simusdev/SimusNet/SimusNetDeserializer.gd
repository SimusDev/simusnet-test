@static_unload
extends RefCounted
class_name SimusNetDeserializer

static var _instance: WeakRef = WeakRef.new()

static func get_instance() -> SimusNetDeserializer:
	return _instance.get_ref()

static var _settings: SimusNetSettings

static var _buffer: StreamPeerBuffer = StreamPeerBuffer.new()

func _init() -> void:
	_settings = SimusNetSettings.get_or_create()

static var __type_and_method: Dictionary[SimusNetSerializer.TYPE, Callable] = {
	SimusNetSerializer.TYPE.IMAGE: parse_image,
	SimusNetSerializer.TYPE.OBJECT: parse_object,
	SimusNetSerializer.TYPE.RESOURCE: parse_resource,
	SimusNetSerializer.TYPE.RESOURCE_CACHED: parse_resource,
	SimusNetSerializer.TYPE.IDENTITY: parse_identity,
	SimusNetSerializer.TYPE.IDENTITY_CACHED: parse_identity,
	SimusNetSerializer.TYPE.NODE: parse_node,
	SimusNetSerializer.TYPE.ARRAY: parse_array,
	SimusNetSerializer.TYPE.ARRAY_TYPED: parse_array,
	SimusNetSerializer.TYPE.DICTIONARY: parse_dictionary,
	SimusNetSerializer.TYPE.CUSTOM: parse_custom,
	SimusNetSerializer.TYPE.NULL: parse_null,
	SimusNetSerializer.TYPE.STRING_NAME : parse_string_name,
	SimusNetSerializer.TYPE.VAR: parse_var,
}

static func parse_custom(data: PackedByteArray) -> Variant:
	_buffer.data_array = data
	var type: SimusNetSerializer.TYPE = _buffer.get_u8()
	var uid: String = _buffer.get_utf8_string()
	var variant: Array = parse_arguments(_buffer.get_data(_buffer.get_size())[1])
	var result: SimusNetCustomSerialization = SimusNetCustomSerialization.new()
	var path: String = "uid://" + uid
	var static_script: Script = load(path)
	if !static_script:
		_throw_error("_parse_custom(): failed to load script %s!" % [path])
		return result._result
	
	result._data = variant
	
	if SimusNetCustomSerialization.find_base_script(static_script).has_method(SimusNetCustomSerialization.METHOD_DESERIALIZE):
		static_script.call(SimusNetCustomSerialization.METHOD_DESERIALIZE, result)
	
	#if result._result == null:
		#_throw_error("_parse_custom(): deserialized variant is null! %s, %s, %s" % [path, variant, load(path)])
	#
	return result._result
	

static func parse_null(data: PackedByteArray) -> Variant:
	return null

static func parse_object(data: PackedByteArray) -> Object:
	_buffer.data_array = data
	var type: SimusNetSerializer.TYPE = _buffer.get_u8()
	
	var result: Object = null
	
	var id: String = _buffer.get_utf8_string()
	if !id.begins_with(":"):
		var scr: Script = load(id)
		if scr:
			result = scr.new()
	else:
		result = ClassDB.instantiate(id)
	
	if is_instance_valid(result):
		var identity: Variant = _buffer.get_var()
		if identity != null:
			SimusNetIdentity.register(result, identity)
		
		var network_params: Dictionary = _buffer.get_var()
		SimusNetNodeSceneReplicator.deserialize_object_network_parameters_to(result, network_params)
	
	return result

static func parse_resource(data: PackedByteArray) -> Resource:
	_buffer.data_array = data
	var type: SimusNetSerializer.TYPE = _buffer.get_u8()
	var result: Resource = null
	if type == SimusNetSerializer.TYPE.RESOURCE_CACHED:
		var id: int = _buffer.get_u16()
		result = load(SimusNetResources.get_cached().get(id))
		if !is_instance_valid(result):
			_throw_error("deserialized resource is null! ID: %s" % id)
	else:
		var str: String = _buffer.get_string()
		result = load(str)
		if !is_instance_valid(result):
			_throw_error("deserialized resource is null! ID: %s" % str)
	
	return result

static func parse_image(data: PackedByteArray) -> Image:
	return null
	#data = SimusNetDecompressor.parse_if_necessary(data)
	#return Image.create_from_data(data.width, 
	#data.height, 
	#data.mipmaps,
	#data.format,
	#data.data
	#)

static func parse_identity(data: PackedByteArray) -> Object:
	_buffer.data_array = data
	var type: SimusNetSerializer.TYPE = _buffer.get_u8()
	var result: SimusNetIdentity = null
	var error: String = ""
	
	if type == SimusNetSerializer.TYPE.IDENTITY_CACHED:
		var id: int = -1
		if _buffer.data_array.size() > 4:
			id = _buffer.get_u32()
		else:
			id = _buffer.get_u16()
		
		
		result = SimusNetIdentity.get_dictionary_by_unique_id().get(id)
		error = "identity with unique ID (%s) was not found on your instance" % id
	else:
		var id: Variant = _buffer.get_var()
		result = SimusNetIdentity.get_dictionary_by_generated_id().get(id)
		error = "identity with ID (%s) was not found on your instance" % id
	
	if result and result.owner:
		return result.owner
	
	_throw_error(error)
	return null

static func parse_node(data: PackedByteArray) -> Node:
	_buffer.data_array = data
	var type: SimusNetSerializer.TYPE = _buffer.get_u8()
	var path: String = _buffer.get_utf8_string()
	return SimusNetSingleton.get_instance().get_node(path)

static func parse_array(data: PackedByteArray) -> Array:
	var local_buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	local_buffer.clear()
	
	local_buffer.data_array = data
	var type: SimusNetSerializer.TYPE = local_buffer.get_u8()
	var serialized: Array = local_buffer.get_var()
	
	if type == SimusNetSerializer.TYPE.ARRAY:
		
		var result: Array = []
		for i in serialized:
			result.append(parse(i))
		
		return result
	
	var typed_builtin: int = local_buffer.get_u16()
	var typed_classname: String = local_buffer.get_utf8_string()
	var has_script: int = local_buffer.get_u8()
	var script: Variant = null
	if has_script == 1:
		script = parse(local_buffer.get_data(local_buffer.get_size())[1])
	
	var result: Array = Array([], typed_builtin, typed_classname, script)
	
	for i in serialized:
		result.append(parse(i))
	return result

static func parse_dictionary(data: PackedByteArray) -> Dictionary:
	_buffer.data_array = data
	var type: SimusNetSerializer.TYPE = _buffer.get_u8()
	var dictionary: Dictionary = _buffer.get_var()
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
	return result

static func parse_string_name(data: PackedByteArray) -> StringName:
	_buffer.data_array = data
	var type: SimusNetSerializer.TYPE = _buffer.get_u8()
	return _buffer.get_var()

static func parse_var(data: PackedByteArray) -> Variant:
	_buffer.data_array = data
	var type: SimusNetSerializer.TYPE = _buffer.get_u8()
	return _buffer.get_var()

static func parse(variant: Variant, try: bool = true) -> Variant:
	if !try:
		return variant
	
	if variant is PackedByteArray:
		_buffer.data_array = variant
		var type: SimusNetSerializer.TYPE = _buffer.get_u8()
		if __type_and_method.has(type):
			return __type_and_method[type].call(variant)
	
	return variant

static func parse_arguments(bytes: PackedByteArray, deserialization: bool = true) -> Array:
	var deserialized: Array = SimusNetArguments.deserialize(bytes)
	if deserialization:
		var parsed: Array = []
		for i in deserialized:
			parsed.append(parse(i))
		return parsed
	return deserialized

static func _throw_error(...args: Array) -> void:
	if _settings.debug_enable:
		printerr("[YOUR UNIQUE ID: %s] [SimusNetDeserializer]: " % SimusNetConnection.get_unique_id())
		printerr(args)
