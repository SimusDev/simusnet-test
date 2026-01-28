@tool
extends Node3D
class_name SD_SoundInstance3D

@export var package: SD_SoundPackage3D : set = set_package
@export var playing: bool = false : set = set_playing

var _logger: SD_Logger = SD_Logger.new(self)

var _players: Array[AudioStreamPlayer3D] = []

func set_package(new: SD_SoundPackage3D) -> void:
	playing = false
	package = new

func get_players() -> Array[AudioStreamPlayer3D]:
	var new: Array[AudioStreamPlayer3D] = []
	for p in _players:
		if is_instance_valid(p):
			new.append(p)
	_players = new
	return _players

func set_playing(value: bool) -> SD_SoundInstance3D:
	if !is_instance_valid(package):
		value = false
	
	playing = value
	
	SD_Nodes.async_clear_all_children(self)
	
	if playing:
		var player: AudioStreamPlayer3D
	
	return self

func _physics_process(delta: float) -> void:
	tick()

func tick() -> void:
	var camera: Camera3D = get_tree().root.get_camera_3d()
	if !camera:
		return
	
	

func play() -> SD_SoundInstance3D:
	set_playing(true)
	return self
