@tool
extends Control

@export var value_field:LineEdit


func get_value() -> String:
	return value_field.text

func set_value(value:String) -> void:
	value_field.text = value
