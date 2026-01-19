@static_unload
extends RefCounted
class_name SimusNetSerializer

static var _settings: SimusNetSettings

const ARRAY_SIZE: int = 2

static func _throw_error(...args: Array) -> void:
	if _settings.debug_enable:
		printerr("[SimusNetSerializer]: ")
		printerr(args)

func _init() -> void:
	_settings = SimusNetSettings.get_or_create()

enum TYPE {
	OBJECT,
	RESOURCE,
	IMAGE,
	IDENTITY,
	NODE,
	NODE_FROM,
	ARRAY,
	DICTIONARY,
}

static var __class_and_method: Dictionary[StringName, Callable] = {
	#"Resource": parse_resource,
	"Object": parse_object,
	"Array": parse_array,
	"Dictionary": parse_dictionary,
	"Image" : parse_image
}

static func _create_parsed(type: TYPE, value: Variant = null) -> Array:
	if value == null:
		return [type]
	return [type, value]

static func parse(variant: Variant, try: bool = true) -> Variant:
	if !try:
		return variant
	
	var parsed: Array = []
	
	var type_string: String = type_string(typeof(variant))
	
	var parsable: bool = false
	for c in __class_and_method:
		if c == type_string:
			parsable = true
			parsed = __class_and_method[c].call(variant)
	
	if !parsable:
		return variant
	
	if parsed.size() <= 1:
		_throw_error("failed to serialize: (%s), %s" % [type_string, variant])
		return variant
	return parsed

static func parse_object(variant: Object) -> Variant:
	if variant is Node:
		return parse_node(variant)
	
	if SimusNetIdentity.try_find_in(variant):
		return parse_identity(variant)
	
	if variant is Resource:
		return parse_resource(variant)
	
	return _create_parsed(TYPE.OBJECT)

static func parse_resource(variant: Resource) -> Variant:
	var id: int = SimusNetResources.get_unique_id(variant)
	if id > -1:
		return _create_parsed(TYPE.RESOURCE, id)
	
	SimusNetResources.cache(variant)
	return _create_parsed(TYPE.RESOURCE, SimusNetResources.get_unique_path(variant))

static func parse_image(image: Image) -> Variant:
	var data: Dictionary = image.data
	data.format = image.get_format()
	return _create_parsed(TYPE.IMAGE, SimusNetCompressor.parse_gzip(data))

static func parse_identity(identity: Object) -> Variant:
	if identity:
		if !identity is SimusNetIdentity:
			identity = SimusNetIdentity.try_find_in(identity)
	
	if identity:
		return _create_parsed(TYPE.IDENTITY, identity.try_serialize_into_variant())
	return _create_parsed(TYPE.IDENTITY)

static func parse_node(node: Node) -> Variant:
	var identity: SimusNetIdentity = SimusNetIdentity.try_find_in(node)
	if identity:
		return parse_identity(identity)
	
	if node.is_inside_tree():
		return _create_parsed(TYPE.NODE, str(node.get_path()))
	
	return _create_parsed(TYPE.NODE)

static func parse_array(array: Array) -> Variant:
	var result: Array = []
	for i in array:
		result.append(parse(i))
	return _create_parsed(TYPE.ARRAY, result)

static func parse_dictionary(dictionary: Dictionary) -> Variant:
	var result: Dictionary = {}
	for key in dictionary:
		result[parse(key)] = parse(dictionary[key])
	return _create_parsed(TYPE.DICTIONARY, result)
