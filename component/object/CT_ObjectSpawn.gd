@tool
@icon("geo_icon.png")
extends Node3D
class_name CT_ObjectSpawn

@export var local: bool = false
@export var object: R_WorldObject : set = set_object

var _preview: Node = null

func set_object(ref: R_WorldObject) -> void:
	object = ref
	if !is_node_ready():
		await ready
	
	if is_instance_valid(_preview):
		_preview.queue_free()
	
	if !is_instance_valid(object):
		return
	
	var prefab: PackedScene = object.viewmodel.world
	if !prefab:
		printerr("viewmodel.world is null!")
		return
	
	if Engine.is_editor_hint():
		_preview = prefab.instantiate()
		add_child(_preview)
		return
	
	var level: LevelInstance = LevelInstance.find_above(self)
	if !level:
		printerr("level instance was not found.")
	
	if local:
		I_WorldObject.new(level, object).instantiate_local().get_instance().global_transform = global_transform
		queue_free()
		return
	
	if !SimusNetConnection.is_server():
		return
	
	I_WorldObject.new(level, object).instantiate().get_instance().global_transform = global_transform
	queue_free()
	
