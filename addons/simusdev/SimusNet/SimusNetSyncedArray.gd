extends SimusNetSyncedType
class_name SimusNetSyncedArray

var _value: Array = [] 

signal on_variant_append(variant: Variant, index: int)
signal on_variant_erase(variant: Variant, index: int)

enum _CHANGE_TYPE {
	ADD,
	REMOVE,
}

func network_get_raw_array() -> Array:
	return _value

func network_size() -> int:
	return _value.size()

func network_append(value: Variant) -> SimusNetSyncedArray:
	_put_change([_CHANGE_TYPE.ADD, SimusNetSerializer.parse(value, config._serialization)])
	return self

func network_erase(value: Variant) -> SimusNetSyncedArray:
	var id: int = _value.find(value)
	if id > -1:
		network_remove_at(id)
	return self

func network_remove_at(id: int) -> SimusNetSyncedArray:
	_put_change([_CHANGE_TYPE.REMOVE, id])
	return self

func _start_replicate_serialize() -> Variant:
	return SimusNetSerializer.parse(_value, config._serialization) 

func _start_replicate_deserialize(data: Variant) -> Variant:
	return SimusNetDeserializer.parse(data, config._serialization) 

func _on_replication_received(data: Variant) -> void:
	_value = data
	_on_value_changed.emit()

func _on_changes_received_authority(changes: Array) -> void:
	_on_changes_received(changes)

func _on_changes_received(changes: Array) -> void:
	for packet: Array in changes:
		var type: int = packet[0]
		var variant: Variant = SimusNetDeserializer.parse(packet[1], config._serialization)
		
		match type:
			_CHANGE_TYPE.ADD:
				_value.append(variant)
				on_variant_append.emit(variant, _value.find(variant))
			_CHANGE_TYPE.REMOVE:
				var value: Variant = _value.find(variant)
				_value.erase(value)
				on_variant_erase.emit(value, variant)
		
	
	_on_value_changed.emit()
