extends Node

const PATH: String = "res://packages/"

func _ready() -> void:
	for file in SD_FileSystem.get_files_with_extension_from_directory(PATH, SD_FileExtensions.EC_RESOURCE):
		var resource: Resource = load(file)
		if resource is R_GamePackage:
			resource.register()
