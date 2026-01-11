@tool
class_name ViewModelRoot3D extends Node3D

enum Type {
	VIEW,
	PLAYER,
}

signal object_changed

@export_tool_button("Update", "CodeFoldedRightArrow") var btn_update = _update

@export var type:Type = Type.VIEW :
	set(val):
		type = val
		_update()
@export var object:R_WorldObject :
	set(new_object):
		object = new_object
		object_changed.emit()
		_update()
	get():
		return object

var _object_instance:Node3D

func _update() -> void:
	if not is_inside_tree():
		return
	if _object_instance:
		_object_instance.free()
		_object_instance = null
	
	if not object:
		SimusDev.console.write_error("%s: object is null" % [self])
		return
	if not object.viewmodel:
		SimusDev.console.write_error("%s: viewmodel is null" % [self])
		return
	
	var prefab:PackedScene
	if type == Type.VIEW:
		prefab = object.viewmodel.view
	elif type == Type.PLAYER:
		prefab = object.viewmodel.player
	
	if not prefab:
		SimusDev.console.write_error("%s: object prefab is null" % [self])
		return
	
	_object_instance = prefab.instantiate()
	add_child(_object_instance)
