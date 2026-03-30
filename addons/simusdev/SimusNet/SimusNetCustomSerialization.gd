@static_unload
extends RefCounted
class_name SimusNetCustomSerialization

#methods in objects
func simusnet_serialize(serialization: SimusNetCustomSerialization) -> void:
	pass

static func simusnet_deserialize(serialization: SimusNetCustomSerialization) -> void:
	pass

const METHOD_SERIALIZE: String = "simusnet_serialize"
const METHOD_DESERIALIZE: String = "simusnet_deserialize"

var _data: Array = []

var _result: Variant
var _result_def: Variant

static var config: SimusNetCustomSerializationConfig = SimusNetCustomSerializationConfig.new()

static func find_base_script(script: Script, recursive: bool = true) -> Script:
	if not script:
		return script
	
	var base: Script = script.get_base_script()
	
	if !base:
		return script
	
	if recursive:
		return find_base_script(script.get_base_script())
	return base

func set_result(new: Variant) -> SimusNetCustomSerialization:
	_result = new
	return self

func get_result() -> Variant:
	return _result

func pack(value: Variant) -> SimusNetCustomSerialization:
	_data.append(value)
	return self

func unpack() -> Variant:
	return _data.pop_front()
