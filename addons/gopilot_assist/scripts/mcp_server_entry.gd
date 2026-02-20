@tool
extends Control

@export var server_name_field:LineEdit
@export var command_field:LineEdit
@export var arg_list:VBoxContainer
@export var arg_sample:Control


func _on_add_arg_btn_pressed() -> void:
	var new_arg = arg_sample.duplicate()
	arg_list.add_child(new_arg)
	new_arg.show()
