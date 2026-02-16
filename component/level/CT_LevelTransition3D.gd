@tool
extends Area3D
class_name CT_LevelTransition3D

@export_file("*.tres", "*.res") var level: String
@export var spawn_point3d_name: StringName = ""

var _level_handler: LevelHandler

var _resource: R_Level

var _logger: SD_Logger = SD_Logger.new(self)

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

func _on_body_entered(body: Node3D) -> void:
	var playable: CT_Playable = SD_ECS.find_first_component_by_script(body, [CT_Playable])
	if playable:
		if playable.is_local():
			UI_LevelTransition.set_level(load(level)).show()
	
	if SimusNetConnection.is_server():
		var level_to: LevelInstance = _level_handler.get_level_by_resource(_resource)
		var point: CT_SpawnPoint3D = level_to.get_spawnpoint_by_name(spawn_point3d_name)
		if !point:
			_logger.debug("cant find spawnpoint by name %s in %s" % [level_to, point])
			return 
		
		if playable:
			level_to.teleport_entity(body)
			body.global_transform = point.global_transform
	
	
	
