extends CharacterBody3D
class_name Player

var _level: LevelInstance

@export var sound: R_SoundObject

@export var debug_queue_free: bool = false : set = set_debug_queue_free

func set_debug_queue_free(val: bool) -> void:
	queue_free()

func _ready() -> void:
	_level = LevelInstance.find_above(self)

func _input(event: InputEvent) -> void:
	if !SimusNet.is_network_authority(self):
		return
	
	if Input.is_action_just_pressed("interact"):
		sound.local_play(_level.get_local_group("group"), Vector3(0, 4, 0) )
		
		
		if SimusNetConnection.is_server():
			var crowbar := I_WorldObject.new(_level, R_WorldObject.find_by_id("object:crowbar"))
			crowbar.instantiate().get_instance().global_position = global_position
