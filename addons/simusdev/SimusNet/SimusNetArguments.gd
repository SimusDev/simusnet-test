@static_unload
class_name SimusNetArguments
# Оптимизированный сериализатор для сетевого плагина с поддержкой double и bool

# Типы данных (используем 4 бита)
enum TYPES {
	INT = 0,
	FLOAT = 1,         # 4 байта
	DOUBLE = 2,        # 8 байт
	BYTES = 3,
	ARRAY = 4,
	DICT = 5,
	SMALL_INT = 6,     # 0-15
	NEG_SMALL_INT = 7, # -15..-1
	ZERO_INT = 8,
	ONE_INT = 9,
	ZERO_FLOAT = 10,
	ONE_FLOAT = 11,
	STRING = 12,
	BOOL_FALSE = 13,   # false
	BOOL_TRUE = 14,    # true
}



const FLOAT_PRECISION_THRESHOLD := 0.000001

# Сериализация
static func serialize(args: Array) -> PackedByteArray:
	var data := PackedByteArray()
	
	if args.is_empty():
		data.append(0)
		return data
	
	data.append(args.size())
	
	for i in args.size():
		data = _serialize_variant(args[i], data)
	
	return data

# Десериализация
static func deserialize(data: PackedByteArray) -> Array:
	if data.is_empty():
		return []
	
	var pos := 0
	
	if pos >= data.size():
		return []
	
	var arg_count := data[pos]
	pos += 1
	
	if arg_count == 0:
		return []
	
	var result := []
	result.resize(arg_count)
	
	for i in arg_count:
		var value_wrapper = [null]
		var new_pos = _deserialize_variant(data, pos, value_wrapper)
		if new_pos <= pos or new_pos > data.size():
			break
		pos = new_pos
		result[i] = value_wrapper[0]
	
	return result

# Проверка необходимости double
static func _needs_double_precision(val: float) -> bool:
	var str_val = str(val)
	var parts = str_val.split(".")
	if parts.size() > 1 and parts[1].length() > 6:
		return true
	return false

# Сериализация Variant
static func _serialize_variant(v, data: PackedByteArray) -> PackedByteArray:
	match typeof(v):
		TYPE_BOOL:
			var val := v as bool
			if val:
				data.append(TYPES.BOOL_TRUE << 4)
			else:
				data.append(TYPES.BOOL_FALSE << 4)
		
		TYPE_INT:
			var val := v as int
			
			if val == 0:
				data.append(TYPES.ZERO_INT << 4)
			elif val == 1:
				data.append(TYPES.ONE_INT << 4)
			elif val >= 0 and val <= 15:
				data.append((TYPES.SMALL_INT << 4) | val)
			elif val < 0 and val >= -15:
				data.append((TYPES.NEG_SMALL_INT << 4) | (-val))
			else:
				data.append(TYPES.INT << 4)
				data = _encode_int(val, data)
		
		TYPE_FLOAT:
			var val := v as float
			
			if val == 0.0:
				data.append(TYPES.ZERO_FLOAT << 4)
			elif val == 1.0:
				data.append(TYPES.ONE_FLOAT << 4)
			elif _needs_double_precision(val):
				data.append(TYPES.DOUBLE << 4)
				data = _encode_double(val, data)
			else:
				data.append(TYPES.FLOAT << 4)
				data = _encode_float(val, data)
		
		TYPE_STRING:
			var val := v as String
			data.append(TYPES.STRING << 4)
			var bytes = val.to_utf8_buffer()
			var len := bytes.size()
			data.append(len & 0xFF)
			data.append((len >> 8) & 0xFF)
			if len > 0:
				data.append_array(bytes)
		
		TYPE_PACKED_BYTE_ARRAY:
			var bytes := v as PackedByteArray
			data.append(TYPES.BYTES << 4)
			
			var len := bytes.size()
			data.append(len & 0xFF)
			data.append((len >> 8) & 0xFF)
			
			if len > 0:
				data.append_array(bytes)
		
		TYPE_ARRAY:
			var arr := v as Array
			data.append(TYPES.ARRAY << 4)
			
			var len := arr.size()
			data.append(len & 0xFF)
			data.append((len >> 8) & 0xFF)
			
			for i in len:
				data = _serialize_variant(arr[i], data)
		
		TYPE_DICTIONARY:
			var dict := v as Dictionary
			data.append(TYPES.DICT << 4)
			
			var len := dict.size()
			data.append(len & 0xFF)
			data.append((len >> 8) & 0xFF)
			
			for key in dict.keys():
				data = _serialize_variant(key, data)
				data = _serialize_variant(dict[key], data)
	
	return data

# Десериализация Variant
static func _deserialize_variant(data: PackedByteArray, pos: int, out_wrapper: Array) -> int:
	if pos >= data.size():
		return pos
	
	var header := data[pos]
	var type := header >> 4
	pos += 1
	
	if pos > data.size():
		return pos - 1
	
	match type:
		TYPES.BOOL_FALSE:
			out_wrapper[0] = false
		
		TYPES.BOOL_TRUE:
			out_wrapper[0] = true
		
		TYPES.ZERO_INT:
			out_wrapper[0] = 0
		
		TYPES.ONE_INT:
			out_wrapper[0] = 1
		
		TYPES.ZERO_FLOAT:
			out_wrapper[0] = 0.0
		
		TYPES.ONE_FLOAT:
			out_wrapper[0] = 1.0
		
		TYPES.SMALL_INT:
			out_wrapper[0] = header & 0x0F
		
		TYPES.NEG_SMALL_INT:
			out_wrapper[0] = -(header & 0x0F)
		
		TYPES.INT:
			var result = _decode_int(data, pos)
			pos = result[0]
			out_wrapper[0] = result[1]
		
		TYPES.FLOAT:
			if pos + 4 <= data.size():
				out_wrapper[0] = _decode_float(data, pos)
				pos += 4
		
		TYPES.DOUBLE:
			if pos + 8 <= data.size():
				out_wrapper[0] = _decode_double(data, pos)
				pos += 8
		
		TYPES.STRING:
			if pos + 2 <= data.size():
				var len := data[pos] | (data[pos + 1] << 8)
				pos += 2
				
				if pos + len <= data.size():
					var bytes := data.slice(pos, pos + len)
					pos += len
					out_wrapper[0] = bytes.get_string_from_utf8()
		
		TYPES.BYTES:
			if pos + 2 <= data.size():
				var len := data[pos] | (data[pos + 1] << 8)
				pos += 2
				
				if pos + len <= data.size():
					var bytes := data.slice(pos, pos + len)
					pos += len
					out_wrapper[0] = bytes
		
		TYPES.ARRAY:
			if pos + 2 <= data.size():
				var len := data[pos] | (data[pos + 1] << 8)
				pos += 2
				
				var arr := []
				arr.resize(len)
				
				var valid = true
				for i in range(len):
					var elem_wrapper = [null]
					var new_pos = _deserialize_variant(data, pos, elem_wrapper)
					if new_pos <= pos:
						valid = false
						break
					pos = new_pos
					arr[i] = elem_wrapper[0]
				
				if valid:
					out_wrapper[0] = arr
		
		TYPES.DICT:
			if pos + 2 <= data.size():
				var len := data[pos] | (data[pos + 1] << 8)
				pos += 2
				
				var dict = {}
				
				var valid = true
				for i in range(len):
					var key_wrapper = [null]
					var value_wrapper = [null]
					
					var new_pos = _deserialize_variant(data, pos, key_wrapper)
					if new_pos <= pos:
						valid = false
						break
					pos = new_pos
					
					new_pos = _deserialize_variant(data, pos, value_wrapper)
					if new_pos <= pos:
						valid = false
						break
					pos = new_pos
					
					if key_wrapper[0] != null:
						dict[key_wrapper[0]] = value_wrapper[0]
				
				if valid:
					out_wrapper[0] = dict
	
	return pos

# Кодирование int
static func _encode_int(val: int, data: PackedByteArray) -> PackedByteArray:
	var uval := val << 1
	if val < 0:
		uval = ((-val) << 1) | 1
	
	var temp := PackedByteArray()
	while true:
		var byte := uval & 0x7F
		uval >>= 7
		if uval == 0:
			temp.append(byte)
			break
		else:
			temp.append(byte | 0x80)
	
	data.append_array(temp)
	return data

# Декодирование int - возвращает массив [новая_позиция, значение]
static func _decode_int(data: PackedByteArray, pos: int) -> Array:
	if pos >= data.size():
		return [pos, 0]
	
	var result := 0
	var shift := 0
	var start_pos := pos
	
	while true:
		if pos >= data.size():
			return [start_pos, 0]
		
		var byte := data[pos]
		pos += 1
		
		result |= (byte & 0x7F) << shift
		shift += 7
		
		if (byte & 0x80) == 0:
			break
	
	var negative := (result & 1) == 1
	result >>= 1
	
	var value = -result if negative else result
	return [pos, value]

# Float функции
static func _encode_float(val: float, data: PackedByteArray) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(4)
	bytes.encode_float(0, val)
	data.append_array(bytes)
	return data

static func _decode_float(data: PackedByteArray, pos: int) -> float:
	var bytes := data.slice(pos, pos + 4)
	return bytes.decode_float(0)

# Double функции
static func _encode_double(val: float, data: PackedByteArray) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, val)
	data.append_array(bytes)
	return data

static func _decode_double(data: PackedByteArray, pos: int) -> float:
	var bytes := data.slice(pos, pos + 8)
	return bytes.decode_double(0)
