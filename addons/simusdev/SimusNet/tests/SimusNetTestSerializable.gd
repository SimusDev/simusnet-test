extends RefCounted
class_name SimusNetTestSerializable

func simusnet_serialize(serialization: SimusNetCustomSerialization) -> void:
	serialization.pack(get_script())

static func simusnet_deserialize(serialization: SimusNetCustomSerialization) -> void:
	var object: SimusNetTestSerializable = serialization.unpack().new()
	serialization.set_result(object)
