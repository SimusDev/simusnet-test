@tool
extends AudioStreamPlayer3D
class_name SD_SoundInstance3D

var _logger: SD_Logger = SD_Logger.new(self)

@export var package: SD_SoundPackage3D : set = set_package
@export var updaterate: float = 20.0
@export var instance_autoplay: bool = false

@export var is_finished: bool = false

@export_tool_button("Play") var _play_cb: Callable = instance_play
@export_tool_button("Stop") var _stop_cb: Callable = instance_stop
@export_tool_button("Reload") var _reload_cb: Callable = instance_reload

signal on_instance_finished()

var _time: float = 0.0

static func is_instance_can_be_created_in_world(_package: SD_SoundPackage3D, global_pos: Vector3) -> bool:
	if !Engine.is_editor_hint():
		if SimusNetConnection.is_dedicated_server():
			return false
	
	var camera: Camera3D = _get_camera()
	if !camera:
		return false
	
	var camera_distance: float = camera.global_position.distance_to(global_pos)
	
	#print(camera_distance)
	
	var _max_distance: float = 0
	
	for data in _package.data:
		if !data:
			continue
		
		if data.max_distance > _max_distance:
			_max_distance = data.max_distance
	
	if _max_distance > 0:
		if camera_distance > _max_distance:
			return false
	
	return true

static func try_create_runtime_in_world(_package: SD_SoundPackage3D) -> SD_SoundInstance3D:
	if Engine.is_editor_hint() or SimusNetConnection.is_dedicated_server():
		return null
	
	var result: SD_SoundInstance3D
	
	var camera: Camera3D = _get_camera()
	if !camera:
		return null
	
	return result

func instance_play() -> SD_SoundInstance3D:
	_perform(true)
	return self

func instance_stop() -> SD_SoundInstance3D:
	_perform(false)
	return self

func _set(property: StringName, value: Variant) -> bool:
	for player in get_players():
		player.set(property, value)
	return false

func set_package(new: SD_SoundPackage3D) -> void:
	package = new

func get_players() -> Array[AudioStreamPlayer3D]:
	var new: Array[AudioStreamPlayer3D] = []
	for p in _data_and_player.values():
		if is_instance_valid(p):
			new.append(p)
	return new

func set_players_property(property: String, value: Variant) -> void:
	for i in get_players():
		i.set(property, value)

func _ready() -> void:
	tick()
	
	if !Engine.is_editor_hint():
		if instance_autoplay:
			instance_play()
	
	_update_states()

static func _get_camera() -> Camera3D:
	if Engine.is_editor_hint():
		var viewport: SubViewport = EditorInterface.get_editor_viewport_3d(0)
		return viewport.get_camera_3d()
	return SimusDev.get_viewport().get_camera_3d()

@export_group("Private")
@export var _data_and_player: Dictionary[SD_SoundData3D, AudioStreamPlayer3D] = {}
@export var _states: Dictionary[SD_SoundData3D, Dictionary]

func _create_player(data: SD_SoundData3D) -> AudioStreamPlayer3D:
	var player: AudioStreamPlayer3D = self.duplicate()
	player.position = Vector3.ZERO
	player.set_script(null)
	player.stream = data.streams.pick_random()
	player.set("parameters/looping", data.looping)
	player.max_distance = data.max_distance
	return player

func instance_reload() -> void:
	for data in _states:
		if !data in package.data:
			_states.erase(data)
	
	SD_Nodes.clear_all_children(self)

func tick() -> void:
	var camera: Camera3D = _get_camera()
	if !camera:
		return
	
	var camera_distance: float = camera.global_position.distance_to(self.global_position)
	
	#print(camera_distance)
	
	
	if !is_instance_valid(package):
		return
	
	for data in _data_and_player:
		if !data in package.data:
			_data_and_player.erase(data)
	
	for data in package.data:
		if !is_instance_valid(data):
			continue
		
		var player: AudioStreamPlayer3D
		var variant: Variant = _data_and_player.get(data)
		if is_instance_valid(variant):
			player = variant
		
		if !is_instance_valid(player):
			_data_and_player.erase(data)
			
			if data.max_distance > 0:
				if camera_distance > data.max_distance:
					continue
			
			if data.min_distance > 0:
				if camera_distance < data.min_distance:
					continue
			
			player = _create_player(data)
			add_child(player)
			player.name = player.name.validate_node_name()
			_read_states(data, player)
			_write_states_tick(data, player)
			_data_and_player.set(data, player)
			if Engine.is_editor_hint():
				player.owner = get_tree().edited_scene_root
		else:
			#_read_states(data, player)
			
			if data.max_distance > 0:
				if camera_distance > data.max_distance:
					_data_and_player.erase(data)
					_write_states_tick(data, player)
					player.queue_free()
			
			if data.min_distance > 0:
				if camera_distance < data.min_distance:
					_data_and_player.erase(data)
					_write_states_tick(data, player)
					player.queue_free()

func _write_states_tick(data: SD_SoundData3D, player: AudioStreamPlayer3D) -> void:
	var dict: Dictionary = _states.get_or_add(data, {})
	if player.stream:
		var playbacks: Dictionary = dict.get_or_add("playbacks", {})
		playbacks[player.stream] = player.get_playback_position()

func _write_state(data: SD_SoundData3D, key: Variant, value: Variant) -> void:
	var dict: Dictionary = _states.get_or_add(data, {})
	dict.set(key, value)

func _read_states(data: SD_SoundData3D, player: AudioStreamPlayer3D) -> void:
	var dict: Dictionary = _states.get_or_add(data, {})
	var _is_playing: bool = dict.get("playing", false)
	
	var playbacks: Dictionary = dict.get_or_add("playbacks", {})
	var pos: float = playbacks.get(player.stream, 0.0)
	if _is_playing:
		player.play(pos)

func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= 1.0 / updaterate:
		tick()
		_time = 0

func _update_states() -> void:
	for data in _data_and_player:
		var player: AudioStreamPlayer3D
		var value: Variant = _data_and_player.get(data)
		if is_instance_valid(value):
			player = value
		
		_read_states(data, player)

func _perform(status: bool) -> void:
	if !Engine.is_editor_hint() and SimusNetConnection.is_dedicated_server():
		return
	
	if !package:
		return
	
	for data in package.data:
		_write_state(data, "playing", status)
	
	for data in _states:
		if !data in package.data:
			_states.erase(data)
	
	_update_states()
