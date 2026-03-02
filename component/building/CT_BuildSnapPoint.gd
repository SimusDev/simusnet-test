@icon("uid://dh3locbu4v34g")
@tool
class_name CT_BuildSnapPoint extends Area3D

@export var allowed_types:Array[R_BuildingType]

func _init() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(5, true)
	set_collision_mask_value(5, true)
