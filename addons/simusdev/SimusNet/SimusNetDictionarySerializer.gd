# SimusNetDictSerializer.gd
@static_unload
class_name SimusNetDictionarySerializer
extends RefCounted

enum DataType {
	NIL = 0,
	BOOL = 1,
	INT8 = 2,
	INT16 = 3,
	INT32 = 4,
	INT64 = 5,
	FLOAT = 6,
	STRING = 7,
	BYTE_ARRAY = 8,
	ARRAY = 9,
	DICT = 10,
	VECTOR2 = 11,
	VECTOR3 = 12
}

static func serialize(data) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	serialize_value(buffer, data)
	return buffer.data_array

static func deserialize(bytes: PackedByteArray):
	var buffer := StreamPeerBuffer.new()
	buffer.data_array = bytes
	return deserialize_value(buffer)

static func serialize_value(buffer: StreamPeerBuffer, value):
	var type := typeof(value)
	
	match type:
		TYPE_NIL:
			buffer.put_8(DataType.NIL)
		
		TYPE_BOOL:
			buffer.put_8(DataType.BOOL)
			buffer.put_8(1 if value else 0)
		
		TYPE_INT:
			buffer.put_8(get_int_type(value))
			write_int(buffer, value)
		
		TYPE_FLOAT:
			buffer.put_8(DataType.FLOAT)
			buffer.put_float(value)
		
		TYPE_STRING:
			buffer.put_8(DataType.STRING)
			var bytes: PackedByteArray = value.to_utf8_buffer()
			buffer.put_32(bytes.size())
			buffer.put_data(bytes)
		
		TYPE_PACKED_BYTE_ARRAY:
			buffer.put_8(DataType.BYTE_ARRAY)
			buffer.put_32(value.size())
			buffer.put_data(value)
		
		TYPE_ARRAY:
			buffer.put_8(DataType.ARRAY)
			buffer.put_32(value.size())
			for item in value:
				serialize_value(buffer, item)
		
		TYPE_DICTIONARY:
			buffer.put_8(DataType.DICT)
			buffer.put_32(value.size())
			for key in value:
				serialize_value(buffer, key)
				serialize_value(buffer, value[key])
		
		TYPE_VECTOR2:
			buffer.put_8(DataType.VECTOR2)
			buffer.put_float(value.x)
			buffer.put_float(value.y)
		
		TYPE_VECTOR3:
			buffer.put_8(DataType.VECTOR3)
			buffer.put_float(value.x)
			buffer.put_float(value.y)
			buffer.put_float(value.z)
		
		_:
			push_error("Unsupported type: ", type)

static func get_int_type(value: int) -> DataType:
	if value >= -128 and value <= 127:
		return DataType.INT8
	elif value >= -32768 and value <= 32767:
		return DataType.INT16
	elif value >= -2147483648 and value <= 2147483647:
		return DataType.INT32
	else:
		return DataType.INT64

static func write_int(buffer: StreamPeerBuffer, value: int):
	match get_int_type(value):
		DataType.INT8:
			buffer.put_8(value)
		DataType.INT16:
			buffer.put_16(value)
		DataType.INT32:
			buffer.put_32(value)
		DataType.INT64:
			buffer.put_64(value)

static func read_int(buffer: StreamPeerBuffer, type: DataType):
	match type:
		DataType.INT8:
			return buffer.get_8()
		DataType.INT16:
			return buffer.get_16()
		DataType.INT32:
			return buffer.get_32()
		DataType.INT64:
			return buffer.get_64()
	return 0

static func deserialize_value(buffer: StreamPeerBuffer):
	var type := buffer.get_8() as DataType
	
	match type:
		DataType.NIL:
			return null
		
		DataType.BOOL:
			return buffer.get_8() == 1
		
		DataType.INT8, DataType.INT16, DataType.INT32, DataType.INT64:
			return read_int(buffer, type)
		
		DataType.FLOAT:
			return buffer.get_float()
		
		DataType.STRING:
			var size := buffer.get_32()
			var bytes: PackedByteArray = buffer.get_data(size)[1]
			return bytes.get_string_from_utf8()
		
		DataType.BYTE_ARRAY:
			var size := buffer.get_32()
			return buffer.get_data(size)[1]
		
		DataType.ARRAY:
			var size := buffer.get_32()
			var arr := []
			for i in size:
				arr.append(deserialize_value(buffer))
			return arr
		
		DataType.DICT:
			var size := buffer.get_32()
			var dict := {}
			for i in size:
				var key: Variant = deserialize_value(buffer)
				var val: Variant = deserialize_value(buffer)
				dict[key] = val
			return dict
		
		DataType.VECTOR2:
			var x := buffer.get_float()
			var y := buffer.get_float()
			return Vector2(x, y)
		
		DataType.VECTOR3:
			var x := buffer.get_float()
			var y := buffer.get_float()
			var z := buffer.get_float()
			return Vector3(x, y, z)
		
		_:
			push_error("Unknown type: ", type)
			return null
