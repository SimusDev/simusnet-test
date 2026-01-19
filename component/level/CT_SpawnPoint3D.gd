@tool
extends Node3D
class_name CT_SpawnPoint3D

var view_mesh:Mesh :
	set(val):
		view_mesh = val
		
		if is_instance_valid(view_mesh_instance):
			view_mesh_instance.mesh = view_mesh

var view_mesh_instance:MeshInstance3D

static var _list: Array[CT_SpawnPoint3D] = []

static func get_list() -> Array[CT_SpawnPoint3D]:
	return _list

func _enter_tree() -> void:
	_list.append(self)

func _exit_tree() -> void:
	_list.erase(self)

func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	if not view_mesh:
		view_mesh = load("res://src/meshes/sp_box_mesh.tres")
	
	if view_mesh_instance:
		if is_instance_valid(view_mesh_instance):
			remove_child(view_mesh_instance)
			view_mesh_instance.queue_free()
		view_mesh_instance = null
	
	view_mesh_instance = MeshInstance3D.new()
	view_mesh_instance.mesh = view_mesh
	add_child(view_mesh_instance)
