extends Node3D
class_name LevelInstance

var _resource: R_Level

const SCENE: PackedScene = preload("uid://c8wx4j8l5ed75")

@onready var _groups_networked: Node3D = $GroupsNetworked
@onready var _groups_local: Node3D = $GroupsLocal

@onready var _logger: SD_Logger = SD_Logger.new(self)

var _spawnpoints: Array[CT_SpawnPoint3D] = []

func get_spawnpoints() -> Array[CT_SpawnPoint3D]:
	return _spawnpoints

func _ready() -> void:
	for group in R_Object.get_level_group_list():
		get_local_group(group)
		get_networked_group(group)
	
	$Prefabs.add_child(_resource.prefab.instantiate())
	
	R_GameStateNodeReference.new(self).on_save_event(
		func(instance: R_GameStateNodeInstance):
			instance.write("objects", _collect_and_get_save_objects())
			
	).on_load_event(
		func(instance: R_GameStateNodeInstance):
			_read_and_spawn_objects(instance.read("objects", {}))
	)

func _collect_and_get_save_objects() -> Dictionary:
	var result: Dictionary = {}
	var saved_objects: int = 0
	for group in _groups_networked.get_children():
		var group_data: Dictionary = result.get_or_add(group.name, {})
		for child in group.get_children():
			if !child.scene_file_path.is_empty():
				var i_world_object: I_WorldObject = I_WorldObject.find_in(child)
				if i_world_object:
					if not i_world_object.get_object().is_supports_gamestate():
						continue
				
				saved_objects += 1
				var child_data: Dictionary = group_data.get_or_add(child.name, {})
				if i_world_object:
					child_data[2] = i_world_object.serialize()
				child_data[0] = load(child.scene_file_path)
				if "transform" in child:
					child_data[1] = child.transform
				
				
				
	
	_logger.debug("saved %s objects." % saved_objects, SD_ConsoleCategories.SUCCESS)
	return result

func _read_and_spawn_objects(objects: Dictionary) -> void:
	var loaded_objects: int = 0
	
	for group_name: String in objects:
		var group: LevelGroup = get_networked_group(group_name)
		group.get_replicator().clear_path_optimization()
		await group.async_clear_all_children()
		
		var group_data: Dictionary = objects[group_name]
		for child_name: String in group_data:
			loaded_objects += 1
			var child_data: Dictionary = group_data[child_name]
			var scene: PackedScene = child_data[0]
			var instance: Node = scene.instantiate()
			instance.name = child_name
			if 1 in child_data:
				instance.transform = child_data[1]
			
			if 2 in child_data:
				I_WorldObject.deserialize(child_data[2], instance, self)
			
			group.add_child(instance)
			
	
	_logger.debug("loaded %s objects." % loaded_objects, SD_ConsoleCategories.SUCCESS)

func _get_group_(group: String, root: Node3D) -> LevelGroup:
	group = group.validate_node_name().to_pascal_case()
	var founded: LevelGroup = root.get_node_or_null(group)
	if founded:
		return founded
	var result: LevelGroup = LevelGroup.new()
	if root == _groups_networked:
		result.networked = true
	result.name = group
	root.add_child(result)
	return result

func get_networked_group(group: String) -> LevelGroup:
	return _get_group_(group, _groups_networked)

func get_local_group(group: String) -> LevelGroup:
	return _get_group_(group, _groups_local)

func get_resource() -> R_Level:
	return _resource

static func find_above(from: Node) -> LevelInstance:
	return SD_ECS.node_find_above_by_script(from, LevelInstance)

static func _create(resource: R_Level) -> LevelInstance:
	var instance: LevelInstance = SCENE.instantiate()
	instance._resource = resource
	instance.name = resource.code
	resource._instance = instance
	return instance
