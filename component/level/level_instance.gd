extends Node3D
class_name LevelInstance

var _resource: R_Level

const SCENE: PackedScene = preload("uid://c8wx4j8l5ed75")

@onready var _groups_networked: Node3D = $GroupsNetworked
@onready var _groups_local: Node3D = $GroupsLocal

@onready var _logger: SD_Logger = SD_Logger.new(self)

func _ready() -> void:
	for group in R_Object.get_group_list():
		get_local_group(group)
		get_networked_group(group)
	
	$Prefabs.add_child(_resource.prefab.instantiate())

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
	return instance
