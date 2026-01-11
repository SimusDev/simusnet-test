class_name LevelHandler extends Node

@export var base_path:String = "res://"
@export var directories:PackedStringArray
@export var level_at_start:R_Level
@export var level_holder:Node

var current_level:R_Level

func _ready() -> void:
	_handle()

func _handle() -> void:
	for directory:String in directories:
		for file in SD_FileSystem.get_all_files_with_extension_from_directory(base_path.path_join(directory), SD_FileExtensions.EC_RESOURCE):
			var resource:Resource = load(file)
			if resource is R_Level:
				resource.register()
	
	if level_at_start:
		change_level(level_at_start)

func clear(safe:bool = true) -> void:
	if safe:
		if not is_instance_valid(level_holder):
			return
	SD_Nodes.clear_all_children(level_holder)

func change_level(to:R_Level) -> void:
	if not is_instance_valid(level_holder):
		return
	clear(false)
	to.instantiate(level_holder)

func change_level_by_code(level_code:StringName) -> void:
	for ref in R_Level.get_reference_list():
		if ref.code == level_code:
			change_level(ref)
