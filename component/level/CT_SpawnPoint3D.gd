extends Node3D
class_name CT_SpawnPoint3D

static var _list: Array[CT_SpawnPoint3D] = []

var _level: LevelInstance

func get_level() -> LevelInstance:
	return _level

static func get_list() -> Array[CT_SpawnPoint3D]:
	return _list

func _enter_tree() -> void:
	_level = LevelInstance.find_above(self)
	_level._spawnpoints.append(self)
	_list.append(self)

func _exit_tree() -> void:
	_level._spawnpoints.erase(self)
	_list.erase(self)
