@static_unload
extends RefCounted
class_name SimusNetDeserializer

static var _settings: SimusNetSettings

func _init() -> void:
	_settings = SimusNetSettings.get_or_create()

static var __type_and_method: Dictionary[SimusNetSerializer.TYPE, Callable] = {
	SimusNetSerializer.TYPE.OBJECT: parse_object,
	SimusNetSerializer.TYPE.RESOURCE: parse_resource,
	SimusNetSerializer.TYPE.IMAGE: parse_image,
	SimusNetSerializer.TYPE.IDENTITY: parse_identity,
	SimusNetSerializer.TYPE.NODE: parse_node,
	SimusNetSerializer.TYPE.ARRAY: parse_array,
	SimusNetSerializer.TYPE.DICTIONARY: parse_dictionary,
}

static func _create_parsed(variant: Variant) -> Variant:
	if variant is Array:
		if variant.size() == SimusNetSerializer.ARRAY_SIZE and typeof(variant[0]) == TYPE_INT:
			return variant[1]
	return variant

static func parse_object(data: Variant) -> Object:
	return _create_parsed(data)

static func parse_resource(data: Variant) -> Resource:
	data = _create_parsed(data)
	if data is String:
		return load(data)
	return load(SimusNetResources.get_cached().get(data))

static func parse_image(data: Variant) -> Image:
	data = _create_parsed(data)
	data = SimusNetDecompressor.parse_gzip(data)
	return Image.create_from_data(data.width, 
	data.height, 
	data.mipmaps,
	data.format,
	data.data
	)

static func parse_identity(data: Variant) -> Object:
	return SimusNetIdentity.try_deserialize_from_variant(_create_parsed(data)).owner

static func parse_node(data: Variant) -> Node:
	return SimusNetSingleton.get_instance().get_node(_create_parsed(data))

static func parse_array(data: Variant) -> Array:
	var parsed: Array = []
	for i in data:
		parsed.append(parse(i))
	return parsed

static func parse_dictionary(dictionary: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in dictionary:
		result[parse(key)] = parse(dictionary[key])
	return result

static func parse(variant: Variant, try: bool = true) -> Variant:
	if !try:
		return variant
	
	if variant is Array:
		if variant.size() == SimusNetSerializer.ARRAY_SIZE:
			var first: Variant = variant.get(0)
			var second: Variant = variant.get(1)
			
			if typeof(first) == TYPE_INT:
				return __type_and_method[first].call(second)
			
			
	return variant

static func _throw_error(...args: Array) -> void:
	if _settings.debug_enable:
		printerr("[SimusNetDeserializer]: ")
		printerr(args)
