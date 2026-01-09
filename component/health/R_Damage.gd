extends Resource
class_name R_Damage

var _source: Object = null
var _value: float = 0.0

func get_source() -> Object:
	return _source

func set_source(source: Object) -> R_Damage:
	_source = source
	return self

func set_value(value: float) -> R_Damage:
	_value = value
	return self

func get_value() -> float:
	return _value

func apply(health: CT_Health) -> R_Damage:
	health.value -= _value
	return self
