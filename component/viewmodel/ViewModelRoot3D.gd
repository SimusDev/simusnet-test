@tool
class_name ViewModelRoot3D extends Node3D

enum Type {
	VIEW,
	PLAYER,
}

signal object_changed

@export var player:Player

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

@export_group("Editor")
@export var enabled_in_editor:bool = true
@export_tool_button("Update", "CodeFoldedRightArrow") var btn_update = _update
@export_tool_button("Reset", "CodeFoldedRightArrow") var btn_clear = _clear.bind(false)

var _object_instance:Node3D

func _clear(safe:bool = true) -> void:
	if not enabled_in_editor and Engine.is_editor_hint():
		return
	if safe:
		if not is_inside_tree():
			return
	if _object_instance:
		_object_instance.free()
		_object_instance = null

func _update() -> void:
	if not is_inside_tree():
		await tree_entered
	if not enabled_in_editor and Engine.is_editor_hint():
		return
	
	if not is_node_ready():
		SimusDev.console.write_info("'%s': waiting for 'ready'" % [self])
		await ready
	
	_clear()
	
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
	_object_instance.set_multiplayer_authority( get_multiplayer_authority() )
	_object_instance.set("player", player)
	if not Engine.is_editor_hint():
		object.set_in(_object_instance)
	
	add_child(_object_instance)
