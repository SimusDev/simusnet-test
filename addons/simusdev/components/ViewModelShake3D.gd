class_name ViewModelShake3D extends Node3D

@export var player: CharacterBody3D
@export var camera_root: Node3D

@export_group("Properties")
@export var crouching_node:Node3D
@export var crouched_property:StringName

@export var sprinting_node:Node3D
@export var sprinting_property:StringName

@export_group("Settings")
@export var snappiness: float = 15.0 
@export var return_speed: float = 8.0 

@export_group("Idle Breathing")
@export var idle_bob_freq: float = 1.5
@export var idle_bob_amp: Vector2 = Vector2(0.002, 0.002)

@export_group("Landing & Jump Juice")
@export var landing_shake_strength: float = 0.015
@export var jump_kickback: float = 0.03
@export var landing_tilt_strength: float = 2.0

@export_group("Recoil Values")
@export var recoil_vertical: float = 0.1
@export var recoil_horizontal: float = 0.05 
@export var recoil_kickback: float = 0.1 

@export_group("ViewModel Bob")
@export_subgroup("Sway")
@export var crouch_bob: float = 4.3
@export var walk_bob: float = 7.3
@export var sprint_bob: float = 12.8
var bob_frequency:float = 0.0

@export_subgroup("Bob Amplitude")
@export var crouch_bob_amplitude:Vector2 = Vector2(0.005, 0.01)
@export var walk_bob_amplitude:Vector2 = Vector2(0.01, 0.02)
@export var sprint_bob_amplitude:Vector2 = Vector2(0.015, 0.03)

var bob_amplitude = walk_bob_amplitude

@export var crouch_offset:Vector3 = Vector3(0.0, 0.05, 0.05)
@export var walk_offset:Vector3 = Vector3(0.0, -0.025, 0.025)
@export var sprint_offset:Vector3 = Vector3(0.0, -0.05, 0.075)
var viewmodel_offset:Vector3 = Vector3.ZERO

var time_elapsed: float = 0.0
var target_position: Vector3
var current_position: Vector3

var accumulated_recoil_pitch: float = 0.0 
var accumulated_recoil_yaw: float = 0.0

var last_velocity_y: float = 0.0
var was_on_floor: bool = true

var is_crouched:bool = false
var is_sprinting:bool = false

func _ready() -> void:
	var auth:bool = is_multiplayer_authority()
	set_process(auth)
	set_process_input(auth) 

func _handle_bob_frequency() -> void:
	if is_crouched:
		bob_frequency = crouch_bob
	elif is_sprinting:
		bob_frequency = sprint_bob
	else:
		bob_frequency = walk_bob

func _handle_viewmodel_offset() -> void:
	if is_crouched:
		if camera_root.rotation.x < -0.75:
			viewmodel_offset = crouch_offset
			return
	
	
	if player.velocity:
		if is_sprinting:
			viewmodel_offset = sprint_offset
		else:
			viewmodel_offset = walk_offset
	else:
		viewmodel_offset = Vector3.ZERO

func _handle_bob_amplitude() -> void:
	if is_crouched:
		bob_amplitude = crouch_bob_amplitude
	elif is_sprinting:
		bob_amplitude = sprint_bob_amplitude
	else:
		bob_amplitude = walk_bob_amplitude

func _handle_landing_and_jumping() -> void:
	if player.is_on_floor() and not was_on_floor:
		var fall_speed = abs(last_velocity_y)
		if fall_speed > 2.0:
			var impact = min(fall_speed * landing_shake_strength, 0.3)
			target_position.y -= impact
			rotation_degrees.x -= impact * landing_tilt_strength * 10.0

	if not player.is_on_floor() and was_on_floor:
		if player.velocity.y > 0:
			target_position.y -= 0.04
			rotation.x -= 0.02

	last_velocity_y = player.velocity.y
	was_on_floor = player.is_on_floor()

func _process(delta: float) -> void:
	is_crouched = crouching_node.get(crouched_property)
	is_sprinting = sprinting_node.get(sprinting_property)
	
	_handle_landing_and_jumping()
	_handle_bob_frequency()
	_handle_viewmodel_offset()
	_handle_bob_amplitude()
	
	var bob_offset = Vector3.ZERO
	
	if player.is_on_floor() and player.velocity.length() > 0.1:
		time_elapsed += delta * bob_frequency
		
		bob_offset.x = sin(time_elapsed) * bob_amplitude.x
		bob_offset.y = sin(time_elapsed * 2.0) * bob_amplitude.y 
	else:
		var idle_time = Time.get_ticks_msec() * 0.001 * idle_bob_freq
		bob_offset.x = sin(idle_time) * idle_bob_amp.x
		bob_offset.y = sin(idle_time * 0.5) * idle_bob_amp.y
		time_elapsed = lerp(time_elapsed, 0.0, delta * 5.0)
	
	target_position = target_position.lerp(Vector3.ZERO, return_speed * delta)
	current_position = current_position.lerp(target_position, snappiness * delta)

	var local_vel = player.global_transform.basis.inverse() * player.velocity
	var target_tilt_z = clamp(-local_vel.x * 0.015, -0.05, 0.05)
	rotation.z = lerp_angle(rotation.z, target_tilt_z, delta * 10.0)

	var final_target = viewmodel_offset + bob_offset + current_position
	
	position = position.lerp(final_target, delta * snappiness)

	rotation.x = lerp_angle(rotation.x, 0.0, delta * return_speed)
