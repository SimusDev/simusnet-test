extends RefCounted
class_name R_KeyBind

var _input_action: StringName

func get_input_action() -> StringName:
	return _input_action

func is_pressed() -> bool:
	return Input.is_action_pressed(_input_action)

func is_just_pressed() -> bool:
	return Input.is_action_just_pressed(_input_action)

func is_just_released() -> bool:
	return Input.is_action_just_released(_input_action)

func _initialize(action: StringName) -> void:
	_input_action = action

static func get_by_action(name: StringName) -> R_KeyBind:
	return s_KeyBindings.get_key_by_action(name)
