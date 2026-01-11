extends Resource
class_name R_LocalData

const EXTENSION: String = ".tres"
const BASE_PATH: String = "user://local_data"

static var _loaded: Dictionary[String, R_LocalData] = {}

@export var _storage: Dictionary = {}

func get_value(key: Variant, default: Variant = null) -> Variant:
	return _storage.get(key, default)

func get_value_or_add(key: Variant, default: Variant) -> Variant:
	return _storage.get_or_add(key, default)

func set_value(key: Variant, value: Variant) -> Variant:
	return _storage.set(key, value) 

func has_key(key: Variant) -> bool:
	return _storage.has(key)

func is_empty() -> bool:
	return _storage.is_empty()

static func get_or_create(folder: String, filename: String) -> R_LocalData:
	var folder_path: String = BASE_PATH.path_join(folder)
	SD_FileSystem.make_directory(folder_path)
	
	var filepath: String = folder_path.path_join(filename) + EXTENSION
	if _loaded.has(filepath):
		return _loaded.get(filepath)
	
	var loaded: Resource = ResourceLoader.load(filepath)
	if loaded:
		if loaded is R_LocalData:
			_loaded[filepath] = loaded
			return loaded
	
	
	var data := R_LocalData.new()
	ResourceSaver.save(data)
	_loaded[filepath] = data
	return data

func save() -> void:
	ResourceSaver.save(self, resource_path)

static func get_or_create_server(folder: String, filename: String) -> R_LocalData:
	return get_or_create("server/".path_join(folder), filename)

static func get_or_create_client(folder: String, filename: String) -> R_LocalData:
	return get_or_create("client/".path_join(folder), filename)
