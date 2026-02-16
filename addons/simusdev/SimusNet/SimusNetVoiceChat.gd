@tool
extends Node
class_name SimusNetVoiceChat

@export var _muted : bool = true

@export var input_volume_threshold : float = 0.05
## The audio quality. Not recommended to go above Medium.
@export_enum("Very High", "High", "Medium", "Low") var audio_quality : int = 2 : 
	set(value):
		audio_quality = value
		update_configuration_warnings()

@export_group("Audio Bus")
## Any extra effects you would like to be added to the record bus.
@export var record_effects : Array[AudioEffect] = []

@export_group("Output")
## Allows you to create 2D or 3D spatial audio, where players can only hear each other when close ingame.
@export_enum("None", "2D", "3D") var spatial_mode : int : 
	set(value):
		spatial_mode = value
		notify_property_list_changed()

var _bus_index : int = -1
var _bus_name : String = "SimusNetVoice"

var _microphone_stream : AudioStreamMicrophone
var _record_effect : AudioEffectCapture

var _output_stream : AudioStreamGenerator
var _output_stream_playback : AudioStreamGeneratorPlayback
## The output player which will play received voice samples.
var _output_player : Node : set = set_output_player

var _input_configured : bool = false
var _output_configured : bool = false

func set_input_device(device_name : String) -> void:
	AudioServer.input_device = device_name

func get_input_devices() -> PackedStringArray:
	return AudioServer.get_input_device_list()

func set_muted(value: bool) -> void:
	_muted = value

func is_muted() -> bool:
	return _muted

func get_max_distance() -> float:
	if _output_player is AudioStreamPlayer2D:
		return _output_player.max_distance
	elif _output_player is AudioStreamPlayer3D:
		return _output_player.max_distance
	return 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	
	SimusNetRPCGodot.register_authority_unreliable_ordered(
		[
			_process_audio,
		], SimusNetChannels.BUILTIN.VOICE_CHAT
	)
	
	_configure_bus()
	set_process(SimusNet.is_network_authority(self))
	
	if _output_player == null:
		return
	
	_configure_auto()


func _configure_auto() -> void:
	if SimusNet.is_network_authority(self):
		_configure_input()
	else:
		_configure_output()

func is_all_configured() -> bool:
	return _output_configured and _input_configured

#func _owner_changed(peer : int) -> void:
	#if SimusNet.is_network_authority(self):
		#_configure_input()
	#else:
		#_configure_output()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if not _input_configured:
		return
	
	if _record_effect.get_frames_available() > 0:
		if _muted:
			_record_effect.clear_buffer()
			return
		
		var recording_data : PackedVector2Array = _record_effect.get_buffer(_record_effect.get_frames_available())
		var data : PackedFloat32Array = PackedFloat32Array()
		
		var sr : float = AudioServer.get_mix_rate()
		match(audio_quality):
			0:
				_sample_raw(recording_data, data)
			1:
				_downsample_half(recording_data, data)
				sr /= 2.0
			2:
				_downsample_quarter(recording_data, data)
				sr /= 4.0
			3:
				_downsample_eighth(recording_data, data)
				sr /= 8.0
		
		
		var max_amp : float = 0.0
		for i in range(data.size()):
			max_amp = max(abs(data[i]), max_amp)
		
		
		if max_amp > input_volume_threshold:
			for peer in SimusNetConnection.get_connected_peers():
				if is_visible_for_peer(peer):
					SimusNetRPCGodot.invoke(_process_audio, data, sr)

func _process_audio(audio : PackedFloat32Array, mixrate : float) -> void:
	if _output_stream.mix_rate != mixrate: _output_stream.mix_rate = mixrate
	for i in range(min(_output_stream_playback.get_frames_available(), audio.size())):
		var d : float = audio[i]
		_output_stream_playback.push_frame(Vector2(d, d))

func _sample_raw(recording_data: PackedVector2Array, data : PackedFloat32Array) -> PackedFloat32Array:
	var frames : int = recording_data.size()
	data.resize(frames)
	for i in range(frames):
		data[i] = (recording_data[i].x + recording_data[i].y) / 2
	return data

func _downsample_half(recording_data: PackedVector2Array, data : PackedFloat32Array) -> PackedFloat32Array:
	var frames : int = recording_data.size()
	var half_frames : int = frames / 2
	data.resize(half_frames)
	for i in range(half_frames):
		var v1 : float = (recording_data[i * 2].x + recording_data[i * 2].y) / 2
		var v2 : float = (recording_data[i * 2 + 1].x + recording_data[i * 2 + 1].y) / 2
		data[i] = (v1 + v2) / 2
	return data

func _downsample_quarter(recording_data: PackedVector2Array, data : PackedFloat32Array) -> PackedFloat32Array:
	var frames : int = recording_data.size()
	var quarter_frames : int = frames / 4
	data.resize(quarter_frames)
	for i in range(quarter_frames):
		var v0 : float = (recording_data[i * 4].x + recording_data[i * 4].y) / 2
		var v1 : float = (recording_data[i * 4 + 1].x + recording_data[i * 4 + 1].y) / 2
		var v2 : float = (recording_data[i * 4 + 2].x + recording_data[i * 4 + 2].y) / 2
		var v3 : float = (recording_data[i * 4 + 3].x + recording_data[i * 4 + 3].y) / 2
		data[i] = (v0 + v1 + v2 + v3) / 4
	return data

func _downsample_eighth(recording_data: PackedVector2Array, data : PackedFloat32Array) -> PackedFloat32Array:
	var frames : int = recording_data.size()
	var eighth_frames : int = frames / 8
	data.resize(eighth_frames)
	for i in range(eighth_frames):
		var sum : float = 0.0
		for j in range(8):
			sum += (recording_data[i * 8 + j].x + recording_data[i * 8 + j].y) / 2
		data[i] = sum / 8
	return data

func _configure_bus() -> void:
	for i in range(AudioServer.bus_count):
		if AudioServer.get_bus_name(i) == _bus_name:
			_record_effect = AudioServer.get_bus_effect(i, AudioServer.get_bus_effect_count(i)-1)
			_bus_index = i
	
	if _bus_index >= 0:
		return
	
	_bus_index = AudioServer.bus_count
	AudioServer.add_bus(_bus_index)
	AudioServer.set_bus_name(_bus_index, _bus_name)
	AudioServer.set_bus_mute(_bus_index, true)
	
	for effect in record_effects:
		AudioServer.add_bus_effect(_bus_index, effect)
	
	_record_effect = AudioEffectCapture.new()
	AudioServer.add_bus_effect(_bus_index, _record_effect)

func _configure_input() -> void:
	if _input_configured:
		return
	_input_configured = true
	
	_microphone_stream = AudioStreamMicrophone.new()
	
	var microphone_player : AudioStreamPlayer = AudioStreamPlayer.new()
	microphone_player.name = "MicIn"
	add_child(microphone_player)
	microphone_player.bus = _bus_name
	microphone_player.stream = _microphone_stream
	microphone_player.play()

func _configure_output() -> void:
	if _output_configured:
		return
	_output_configured = true
	
	_output_stream = AudioStreamGenerator.new()
	_output_stream.buffer_length = 0.1
	_output_player.stream = _output_stream
	_output_player.play()
	
	_output_stream_playback = _output_player.get_stream_playback()

func set_output_player(p : Node) -> void:
	_output_player = p
	_configure_auto()
	update_configuration_warnings()

func _get_property_list() -> Array:
	var properties : Array = []
	
	var type : String = ""
	match(spatial_mode):
		0:
			type = "AudioStreamPlayer"
		1:
			type = "AudioStreamPlayer2D"
		2:
			type = "AudioStreamPlayer3D"
	
	properties.append({
		"name" : "_output_player",
		"type" : TYPE_OBJECT,
		"hint" : PROPERTY_HINT_NODE_TYPE,
		"hint_string" : type,
		"usage" : PROPERTY_USAGE_DEFAULT
	})
	
	return properties

func is_visible_for_peer(peer: int) -> bool:
	return true

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = []
	
	#warnings.append("The VoiceChat Node is experimental. Please report any issues on GitHub.")
	
	if _output_player == null:
		warnings.append("No output AudioStreamPlayer assigned.")
	
	if audio_quality < 2:
		warnings.append("Higher audio quality will use up significantly more data.")
	
	return warnings
