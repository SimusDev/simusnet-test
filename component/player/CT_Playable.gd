extends Node
class_name CT_Playable

@export var node: Node3D

static var _list: Array[CT_Playable] = []

static func get_list() -> Array[CT_Playable]:
	return _list

func _ready() -> void:
	EVENT.on_player_spawned.setup(self).publish()

func _enter_tree() -> void:
	if !node:
		node = get_parent()
	
	_list.append(self)

func _exit_tree() -> void:
	_list.erase(self)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			EVENT.on_player_despawned.setup(self).publish()
