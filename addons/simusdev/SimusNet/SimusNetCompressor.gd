@static_unload
extends RefCounted
class_name SimusNetCompressor

static var _buffer: StreamPeerBuffer = StreamPeerBuffer.new()

const COMPRESSION_DEFLATE_BYTES: int = 256
const COMPRESSION_ZSTD_BYTES: int = 4096

static var BYTES_SIZE_AND_METHODS: Dictionary[int, FileAccess.CompressionMode] = {
	COMPRESSION_DEFLATE_BYTES: FileAccess.CompressionMode.COMPRESSION_DEFLATE,
	COMPRESSION_ZSTD_BYTES: FileAccess.CompressionMode.COMPRESSION_ZSTD,
}

static func parse_gzip(variant: Variant) -> PackedByteArray:
	return parse(variant, FileAccess.COMPRESSION_GZIP)

static func parse(variant: Variant, mode: FileAccess.CompressionMode = FileAccess.CompressionMode.COMPRESSION_DEFLATE) -> PackedByteArray:
	var bytes: PackedByteArray = var_to_bytes(variant)
	var compressed: PackedByteArray = bytes.compress(mode)
	return compressed

static func parse_if_necessary(variant: Variant) -> Variant:
	var bytes: PackedByteArray = var_to_bytes(variant)
	
	for b_size in BYTES_SIZE_AND_METHODS:
		if bytes.size() >= b_size:
			_buffer.clear()
			_buffer.put_u32(bytes.size())
			_buffer.put_data(bytes.compress(BYTES_SIZE_AND_METHODS[b_size]))
			return _buffer.data_array
	
	return variant
