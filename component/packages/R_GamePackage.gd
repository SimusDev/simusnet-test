extends Resource
class_name R_GamePackage

@export var id: StringName = ""
@export_dir var objects_dir: String = ""

func get_handler() -> CT_ObjectHandler:
	return s_GameObjects.handler_register(id)

func register() -> void:
	for file in SD_FileSystem.get_all_files_with_extension_from_directory(objects_dir, SD_FileExtensions.EC_RESOURCE):
		var resource: Resource = load(file)
		if resource is R_Object:
			if resource.id.is_empty():
				resource.id = resource.resource_path.get_file().get_basename()
			get_handler().register(resource.id, resource, id)

func unregister() -> void:
	pass
