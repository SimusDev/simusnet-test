@tool
extends Area3D
class_name CT_LevelTransition3D

@export_file("*.tres", "*.res") var level: String
@export var spawn_point3d_name: String = ""

var _level_handler: LevelHandler

var _resource: R_Level

var _logger: SD_Logger = SD_Logger.new(self)

const META: StringName = &"CT_LevelTransition3D"

func _ready() -> void:
	monitorable = false
	
	if Engine.is_editor_hint():
		return
	
	_resource = load(level)
	
	if !_resource:
		_logger.debug("level resource is null.", SD_ConsoleCategories.ERROR)
		return
	
	if !_resource is R_Level:
		_logger.debug("level resource must inherit from R_Level!!!.", SD_ConsoleCategories.ERROR)
		return
	
	_level_handler = LevelInstance.find_above(self).get_handler()
	
	body_entered.connect(_on_body_entered)

static func get_last_from(entity: Node3D) -> CT_LevelTransition3D:
	return SD_Variables.get_or_add_object_meta(entity, META, null)

func _on_body_entered(body: Node3D) -> void:
	SD_Variables.set_object_meta(body, META, self)
	
	var playable: CT_Playable = SD_ECS.find_first_component_by_script(body, [CT_Playable])
	if playable:
		if playable.is_local():
			UI_LevelTransition.set_level(load(level)).try_show_with_cooldown()
	
	
	if playable:
		return
	
	try_teleport_entity(body)

func try_teleport_entity(entity: Node3D) -> void:
	if !SimusNetConnection.is_server():
		return
	
	var level_to: LevelInstance = _level_handler.get_level_by_resource(_resource)
	var point: CT_SpawnPoint3D = level_to.get_spawnpoint_by_name(spawn_point3d_name)
	if !point:
		_logger.debug("cant find spawnpoint by name %s in %s" % [level_to, point])
		return 
	
	level_to.teleport_entity(entity)
	entity.global_transform = point.global_transform
