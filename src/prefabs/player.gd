extends CharacterBody3D
class_name Player

var _level: LevelInstance
func get_level() -> LevelInstance:
	return _level

static var _local: Player
static func get_local() -> Player:
	return _local

@export var sound: R_SoundObject

@export var debug_queue_free: bool = false : set = set_debug_queue_free

func set_debug_queue_free(val: bool) -> void:
	queue_free()

func _ready() -> void:
	if SimusNet.is_network_authority(self):
		_local = self
	_level = LevelInstance.find_above(self)
