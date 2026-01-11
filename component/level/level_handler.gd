class_name LevelHandler extends Node

signal level_changed

@export var base_path:String = "res://"
@export var directories:PackedStringArray
@export var level_at_start:R_Level
@export var level_holder:Node

var current_level:R_Level

func _ready() -> void:
	SimusNetRPC.register(
		[
			_send,
		],
		SimusNetRPCConfig.new().flag_mode_any_peer()
	)
	SimusNetRPC.register(
		[_receive],
		SimusNetRPCConfig.new().flag_mode_server_only()
	)
	_handle()
	
	if level_at_start and SimusNetConnection.is_server():
		change_level(level_at_start)
	
	if not SimusNetConnection.is_server():
		SimusNetRPC.invoke_on_server(_send)
	
	

func _send() -> void:
	SimusNetRPC.invoke_on(
		SimusNetRemote.sender_id,
		_receive,
		current_level
	)

func _receive(_current_level:R_Level) -> void:
	current_level = _current_level
	change_level(current_level)

func _handle() -> void:
	for directory:String in directories:
		for file in SD_FileSystem.get_all_files_with_extension_from_directory(base_path.path_join(directory), SD_FileExtensions.EC_RESOURCE):
			var resource:Resource = load(file)
			if resource is R_Level:
				resource.register()


func clear(safe:bool = true) -> void:
	if safe:
		if not is_instance_valid(level_holder):
			return
	SD_Nodes.clear_all_children(level_holder)

func change_level(to:R_Level) -> void:
	if not is_instance_valid(level_holder):
		return
	clear(false)
	current_level = to
	if to:
		to.instantiate(level_holder)
	level_changed.emit()

func change_level_by_code(level_code:StringName) -> void:
	for ref in R_Level.get_reference_list():
		if ref.code == level_code:
			change_level(ref)
