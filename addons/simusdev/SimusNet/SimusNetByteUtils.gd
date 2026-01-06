@static_unload
extends RefCounted
class_name SimusNetByteUtils

static func array_pack_u8(value: int) -> PackedByteArray:
	var result: PackedByteArray = PackedByteArray()
	result.resize(1)
	result.encode_u8(0, value)
	return result

static func array_unpack_u8(bytes: PackedByteArray) -> int:
	return bytes.decode_u8(0)

static func array_pack_u16(value: int) -> PackedByteArray:
	var result: PackedByteArray = PackedByteArray()
	result.resize(2)
	result.encode_u16(0, value)
	return result

static func array_unpack_u16(bytes: PackedByteArray) -> int:
	return bytes.decode_u16(0)

static func array_pack_u32(value: int) -> PackedByteArray:
	var result: PackedByteArray = PackedByteArray()
	result.resize(4)
	result.encode_u32(0, value)
	return result

static func array_unpack_u32(bytes: PackedByteArray) -> int:
	return bytes.decode_u32(0)
