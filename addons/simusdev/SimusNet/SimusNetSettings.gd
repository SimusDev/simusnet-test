extends Resource
class_name SimusNetSettings

@export_group("Server", "server")
@export var server_info:SimusNetServerInfo = null

@export_group("Synchronization", "synchronization")
@export var synchronization_transform_batch_count: int = 25
#@export var synchronization_var_replicate_batch_count: int = 25
#@export var synchronization_var_send_batch_count: int = 10


#@export_group("Time", "time")
#@export var time_tickrate: float = 48.0 : set = set_time_tickrate
#func set_time_tickrate(tickrate: float) -> void:
	#time_tickrate = tickrate
	#on_time_tickrate_changed.emit()

@export_group("Visibility", "visibility")
@export var visibility_auto_handling: bool = true

signal on_time_tickrate_changed()

#@export_group("Connection", "connection")
#@export var connection_max_peers: int = 512

@export_group("Debug", "debug")
@export var debug_enable: bool = true

const FILEPATH: String = "res://simusnet.tres"

static var ___ref: SimusNetSettings

static func get_or_create() -> SimusNetSettings:
	if ___ref:
		return ___ref
	
	var resource: Resource = ResourceLoader.load(FILEPATH)
	if resource:
		___ref = resource
		return resource
	
	resource = SimusNetSettings.new()
	___ref = resource
	ResourceSaver.save(resource, FILEPATH)
	return resource
