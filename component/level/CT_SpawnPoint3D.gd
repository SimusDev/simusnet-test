extends Node3D
class_name CT_SpawnPoint3D

static var _list: Array[CT_SpawnPoint3D] = []

static func get_list() -> Array[CT_SpawnPoint3D]:
	return _list

func _enter_tree() -> void:
	_list.append(self)

func _exit_tree() -> void:
	_list.erase(self)
