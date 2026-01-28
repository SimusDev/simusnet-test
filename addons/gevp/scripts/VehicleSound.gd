class_name VehicleSound extends Node3D

@export var vehicle: Vehicle
@export var vehicle_skid_detector: VehicleSkidDetector

@export_group("Settings")
@export var sample_rpm := 3000.0
@export var max_rpm := 8000.0
@export var pitch_min := 0.5
@export var pitch_max := 3.0

@export_group("Streams")
@export var transmission: AudioStream
@export var wheels_drifting: AudioStream
@export_subgroup("Engine")
@export var engine_low: AudioStream
@export var engine_med: AudioStream
@export var engine_high: AudioStream

var engine_low_player: AudioStreamPlayer3D
var engine_med_player: AudioStreamPlayer3D
var engine_high_player: AudioStreamPlayer3D
var transmission_player: AudioStreamPlayer3D
var wheels_player: AudioStreamPlayer3D

func _ready() -> void:
	engine_low_player = _setup_player(engine_low)
	engine_med_player = _setup_player(engine_med)
	engine_high_player = _setup_player(engine_high)
	transmission_player = _setup_player(transmission)
	wheels_player = _setup_player(wheels_drifting)

func _setup_player(stream: AudioStream) -> AudioStreamPlayer3D:
	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	player.autoplay = true
	player.volume_db = -80
	add_child(player)
	return player

func _physics_process(delta: float) -> void:
	if not vehicle: return
	
	_update_engine_sound()
	_update_transmission_sound()
	_update_wheels_sound(delta)

func _update_engine_sound() -> void:
	var rpm = vehicle.motor_rpm
	var rpm_normalized = clamp(rpm / max_rpm, 0.0, 1.0)
	
	var desired_pitch = clamp(rpm / sample_rpm, pitch_min, pitch_max)
	engine_low_player.pitch_scale = desired_pitch
	engine_med_player.pitch_scale = desired_pitch
	engine_high_player.pitch_scale = desired_pitch

	engine_low_player.volume_db = linear_to_db(clamp(1.5 - rpm_normalized * 3.0, 0.0, 1.0))
	engine_med_player.volume_db = linear_to_db(clamp(1.0 - abs(rpm_normalized - 0.5) * 2.0, 0.0, 1.0))
	engine_high_player.volume_db = linear_to_db(clamp((rpm_normalized - 0.5) * 2.0, 0.0, 1.0))

func _update_transmission_sound() -> void:
	var speed = vehicle.linear_velocity.length()
	var speed_normalized = clamp(speed / 50.0, 0.0, 1.0)
	
	transmission_player.pitch_scale = 0.5 + speed_normalized
	transmission_player.volume_db = linear_to_db(speed_normalized * 0.8)

func _update_wheels_sound(delta: float) -> void:
	var target_linear_vol = vehicle_skid_detector.get_skid_intensity()
	var current_linear_vol = db_to_linear(wheels_player.volume_db)
	
	var smooth_speed = 5.0
	var lerped = lerp(current_linear_vol, target_linear_vol, smooth_speed * delta)
	lerped = clamp(lerped, 0.001, 1.0)
	wheels_player.volume_db = linear_to_db(lerped)
	
	wheels_player.pitch_scale = 1.0 + (target_linear_vol * 0.2)
