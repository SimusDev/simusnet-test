@tool
extends Control

@export var parent_node:Node

signal can_drop_data(at_position:Vector2, data:Variant)
signal drop_data(at_position:Vector2, data:Variant)
signal get_drag_data(at_position:Vector2)

@export var can_drop_data_function:String = "can_drop_data"

@export var drop_data_function:String = "drop_data"

@export var get_drag_data_function:String ="get_drag_data"

# 
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	can_drop_data.emit(at_position, data)
	if can_drop_data_function.is_empty() or !parent_node:
		return false
	var result:bool = await parent_node.call(can_drop_data_function, at_position, data, self)
	return result


func _drop_data(at_position: Vector2, data: Variant) -> void:
	drop_data.emit(at_position, data)
	if drop_data_function.is_empty() or !parent_node:
		return
	parent_node.call(drop_data_function, at_position, data, self)


func _get_drag_data(at_position: Vector2) -> Variant:
	get_drag_data.emit(at_position)
	if get_drag_data_function.is_empty() or !parent_node:
		return null
	return await parent_node.call(get_drag_data_function, at_position, self)
