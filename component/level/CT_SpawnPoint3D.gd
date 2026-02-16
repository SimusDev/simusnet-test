@tool
extends Node3D
class_name CT_SpawnPoint3D

@export var spawn_name:StringName :
	set(val):
		spawn_name = val
		
		if is_instance_valid(spawn_name_label):
			if not is_node_ready():
				await ready
			
			print(name)
			
			if val.is_empty():
				spawn_name_label.text = name
			else:
				spawn_name_label.text = val

var spawn_name_label:Label3D

var view_mesh:Mesh :
	set(val):
		view_mesh = val
		
		if is_instance_valid(view_mesh_instance):
			view_mesh_instance.mesh = view_mesh

var view_mesh_instance:MeshInstance3D

static var _list: Array[CT_SpawnPoint3D] = []

var _level: LevelInstance

func get_level() -> LevelInstance:
	return _level

static func get_list() -> Array[CT_SpawnPoint3D]:
	return _list

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	
	_level = LevelInstance.find_above(self)
	_level._spawnpoints.append(self)
	_list.append(self)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	
	_level._spawnpoints.erase(self)
	_list.erase(self)

func _ready() -> void:
	if !Engine.is_editor_hint():
		if !SimusNetConnection.is_server():
			queue_free()
	
	if not Engine.is_editor_hint():
		return
	
	if not view_mesh:
		view_mesh = load("res://src/meshes/sp_box_mesh.tres")
	
	if spawn_name_label:
		if is_instance_valid(spawn_name_label):
			remove_child(spawn_name_label)
			spawn_name_label.queue_free()
		spawn_name_label = null
	
	spawn_name_label = Label3D.new()
	spawn_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	if spawn_name.is_empty():
		spawn_name_label.text = &"[SpawnPoint] " + name
	else:
		spawn_name_label.text = &"[SpawnPoint] " + spawn_name
	spawn_name_label.position.y = 1.2
	add_child(spawn_name_label)
	
	if view_mesh_instance:
		if is_instance_valid(view_mesh_instance):
			remove_child(view_mesh_instance)
			view_mesh_instance.queue_free()
		view_mesh_instance = null
	
	view_mesh_instance = MeshInstance3D.new()
	view_mesh_instance.mesh = view_mesh
	view_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view_mesh_instance)
