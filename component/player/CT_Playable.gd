extends Node
class_name CT_Playable

@export var node: Node3D

static var _list: Array[CT_Playable] = []

static var _local: CT_Playable

static func get_list() -> Array[CT_Playable]:
	return _list

static func get_local() -> CT_Playable:
	if !is_instance_valid(_local):
		_local = null
	return _local

func is_local() -> bool:
	return get_local() == self

func _ready() -> void:
	SD_ECS.append_to(node, self)
	
	if SimusNet.is_network_authority(self):
		_local = self
		EVENT.on_player_spawned_local.setup(self).publish()
	
	EVENT.on_player_spawned.setup(self).publish()

static func find_in(target: Node) -> CT_Playable:
	return SD_ECS.find_first_component_by_script(target, [CT_Playable])

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
			if self == get_local():
				EVENT.on_player_despawned_local.setup(self).publish()
