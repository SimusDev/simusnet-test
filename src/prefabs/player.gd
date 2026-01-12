extends CharacterBody3D
class_name Player

var _level: LevelInstance

@export var sound: R_SoundObject

func _ready() -> void:
	_level = LevelInstance.find_above(self)

func _input(event: InputEvent) -> void:
	if !SimusNet.is_network_authority(self):
		return
	
	if Input.is_action_just_pressed("interact"):
		sound.local_play(self, Vector3.ZERO)
		
		return
		if SimusNetConnection.is_server():
			var crowbar := I_WorldObject.new(_level, R_WorldObject.find_by_id("object:crowbar"))
			crowbar.instantiate().get_instance().global_position = global_position
