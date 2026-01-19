extends R_Object
class_name R_UI

@export var global: bool = false
@export var layer: int = 0
@export var prefab: PackedScene

static var _uis: Dictionary[String, R_UI]

var _instance: Node

signal on_instance_set()

func async_get_instance() -> Node:
	if !is_instance_valid(_instance):
		await on_instance_set
	return _instance

static func get_ui_list() -> Array[R_UI]:
	return _uis.values()

static func find_by_id(value: String) -> R_UI:
	return _uis.get(value)

func _registered() -> void:
	super()
	_uis[id] = self

func _unregistered() -> void:
	super()
	_uis.erase(id)

static func get_group() -> String:
	return "ui"
