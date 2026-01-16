class_name CT_DetectHeight extends Node3D

signal detected

@export var enabled:bool = true
@export var value:float = 0.0
@export var instruction:Variant.Operator = OP_EQUAL

var _was_detected:bool = false

func _ready() -> void:
	if SimusNet.is_network_authority(self):
		set_notify_transform(true)

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_handle()

func _handle() -> void:
	if not SimusNet.is_network_authority(self):
		return
	if not enabled or _was_detected:
		return
	
	if SimusNetConnection.is_server():
		match instruction:
			OP_EQUAL:
				if global_position.y == value: _detected()
			OP_LESS_EQUAL:
				if global_position.y <= value: _detected()
			OP_GREATER_EQUAL:
				if global_position.y >= value: _detected()
			OP_LESS:
				if global_position.y < value: _detected()
			OP_GREATER:
				if global_position.y > value: _detected()

func _detected() -> void:
	_was_detected = true
	detected.emit()
