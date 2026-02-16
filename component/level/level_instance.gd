extends Node3D
class_name LevelInstance

var _resource: R_Level

const SCENE: PackedScene = preload("uid://c8wx4j8l5ed75")

@onready var _groups_networked: Node3D = $GroupsNetworked
@onready var _groups_local: Node3D = $GroupsLocal

@onready var _logger: SD_Logger = SD_Logger.new(self)

var _handler: LevelHandler
var _spawnpoints: Array[CT_SpawnPoint3D] = []
var _players: Array[CT_Playable] = []

func get_handler() -> LevelHandler:
	return _handler

func _player_entered(player: CT_Playable) -> void:
	_players.append(player)
	_handler._player_entered(player, self)

func _player_exited(player: CT_Playable) -> void:
	_players.erase(player)
	_handler._player_exited(player, self)


func get_players() -> Array[CT_Playable]:
	return _players

func get_player_by_peer_id(peer: int) -> CT_Playable:
	for p in get_players():
		if p.get_peer_id() == peer:
			return p
	return null

static func get_current() -> LevelInstance:
	var playable: CT_Playable = CT_Playable.get_local()
	if playable:
		return playable.get_level()
	return null

static func get_global_position_from(from: Variant) -> Vector3:
	if from is Vector3:
		return from
	
	if from is Node3D:
		return from.global_position
	
	return Vector3.ZERO

func get_spawnpoints() -> Array[CT_SpawnPoint3D]:
	return _spawnpoints

func get_spawnpoint_by_name(spawn: StringName) -> CT_SpawnPoint3D:
	for i in get_spawnpoints():
		if i.name == spawn:
			return i
	return null

func _ready() -> void:
	position = _resource.position
	
	SimusNetIdentity.register(self)
	
	for group in R_Object.get_level_group_list():
		get_local_group(group)
		get_networked_group(group)
	
	_instantiate_file_prefabs(_resource.prefabs, $P_Prefabs)
	
	if SimusNetConnection.is_server():
		_instantiate_file_prefabs(_resource.server_prefabs, $P_Server)
	
	if SimusNetConnection.is_client():
		_instantiate_file_prefabs(_resource.client_prefabs, $P_Client)
	
	R_GameStateNodeReference.new(self).on_save_event(
		func(instance: R_GameStateNodeInstance):
			instance.write("objects", _collect_and_get_save_objects())
			
	).on_load_event(
		func(instance: R_GameStateNodeInstance):
			_read_and_spawn_objects(instance.read("objects", {}))
	)

func _enter_tree() -> void:
	_handler._levels[_resource] = self

func _exit_tree() -> void:
	_handler._levels.erase(_resource)

func _instantiate_file_prefabs(prefabs: Array[String], to: Node) -> void:
	for file in prefabs:
		var scene: PackedScene = load(file)
		if scene:
			to.add_child(scene.instantiate(), true)

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

func clear_objects() -> void:
	if !SimusNetConnection.is_server():
		return
	
	for group: LevelGroup in _groups_networked.get_children(): 
		group.get_replicator().clear_path_optimization()
		group.async_clear_all_children()

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

func teleport_entity(entity: Node3D) -> void:
	if !SimusNetConnection.is_server():
		_logger.debug("teleport_entity(): only server can teleport entities. %s" % entity, SD_ConsoleCategories.ERROR)
		return
	
	var level_group: LevelGroup = LevelGroup.find_above(entity)
	if !level_group:
		_logger.debug("teleport_entity(): cant find level group above %s." % entity, SD_ConsoleCategories.ERROR)
		return
	
	if level_group.get_level() == self:
		return
	
	var teleport_to: LevelGroup = get_networked_group(level_group.name)
	entity.reparent(teleport_to)

static func find_above(from: Node) -> LevelInstance:
	return SD_ECS.node_find_above_by_script(from, LevelInstance)

static func _create(resource: R_Level) -> LevelInstance:
	var instance: LevelInstance = SCENE.instantiate()
	instance._resource = resource
	instance.name = resource.code
	resource._instance = instance
	return instance
