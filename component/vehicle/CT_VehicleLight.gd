class_name CT_VehicleLight extends Node3D

@export var turn_on_command:StringName
@export var turn_off_command:StringName

@export_group("Custom Settings")
@export var custom_vehicle:Vehicle

var vehicle:Vehicle

func _recieve_command(command_name:StringName) -> void:
	pass
