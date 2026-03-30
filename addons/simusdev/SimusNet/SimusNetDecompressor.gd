@static_unload
extends RefCounted
class_name SimusNetDecompressor

static var _buffer: StreamPeerBuffer = StreamPeerBuffer.new()

static func parse_gzip(bytes: PackedByteArray, mode: FileAccess.CompressionMode = FileAccess.CompressionMode.COMPRESSION_DEFLATE) -> Variant:
	return parse(bytes, FileAccess.COMPRESSION_GZIP)

static func parse(bytes: PackedByteArray, mode: FileAccess.CompressionMode = FileAccess.CompressionMode.COMPRESSION_DEFLATE) -> Variant:
	return bytes_to_var(bytes.decompress_dynamic(-1, mode))

static func parse_if_necessary(variant: Variant) -> Variant:
	if variant is PackedByteArray:
		for b_size in SimusNetCompressor.BYTES_SIZE_AND_METHODS:
			_buffer.data_array = variant
			var original_size: int = _buffer.get_u32()
			var original_bytes: PackedByteArray = _buffer.get_partial_data(variant.size() - 4)[1]
			
			if original_size >= b_size:
				return bytes_to_var(original_bytes.decompress(original_size, SimusNetCompressor.BYTES_SIZE_AND_METHODS[b_size]))
	
	return variant
