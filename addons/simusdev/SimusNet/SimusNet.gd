@static_unload
extends RefCounted
class_name SimusNet

const SERVER_ID: int = 1

static var _stream_buffer: StreamPeerBuffer = StreamPeerBuffer.new()

enum PACKET {
	RPC,
	RPC_DEFLATE,
	RPC_ZSTD,
	RPC_ASYNC,
	RPC_ASYNC_DELFATE,
	RPC_ASYNC_ZSTD,
	VARIABLE_REPLICATE,
	VARIABLES,
	VARIABLES_DEFLATE,
	VARIABLES_ZSTD,
}

static func serialize_packet(type: PACKET, data: PackedByteArray) -> PackedByteArray:
	_stream_buffer.clear()
	_stream_buffer.put_u8(type)
	_stream_buffer.put_data(data)
	return _stream_buffer.data_array

static func deserialize_packet(packet: PackedByteArray) -> Array:
	_stream_buffer.data_array = packet
	var type: PACKET = _stream_buffer.get_u8()
	return [type, _stream_buffer.get_data(_stream_buffer.get_size())[1]]

static func is_network_authority(object: Object) -> bool:
	return get_network_authority(object) == SimusNetConnection.get_unique_id()

static func get_network_authority(object: Object) -> int:
	if is_instance_valid(object):
		if object.has_method("get_multiplayer_authority"):
			return object.get_multiplayer_authority()
	return SimusNetConnection.SERVER_ID
