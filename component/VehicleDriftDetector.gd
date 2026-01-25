class_name VehicleDriftDetector extends Node


signal drift_started(drift_angle, intensity)
signal drift_ended(drift_duration, max_angle)
signal drift_updated(angle, intensity, speed)

@export var min_drift_angle: float = deg_to_rad(15)
@export var min_speed: float = 10.0  # км/ч
@export var min_throttle: float = 0.2
@export var slip_threshold: float = 0.3

@export var vehicle: Vehicle
var is_drifting := false
var drift_timer := 0.0
var max_drift_angle := 0.0

func _physics_process(delta: float) -> void:
	if not vehicle:
		return
	
	var was_drifting = is_drifting
	
	var velocity = vehicle.local_velocity
	var speed_kmh = vehicle.speed * 3.6
	
	if speed_kmh < min_speed:
		is_drifting = false
		return
	
	var drift_angle = calculate_drift_angle()
	var slip_ratio = calculate_slip_ratio()
	
	is_drifting = (
		abs(drift_angle) > min_drift_angle and
		slip_ratio > slip_threshold and
		vehicle.throttle_input > min_throttle and
		vehicle.speed > 2.0
	)
	
	if is_drifting and not was_drifting:
		emit_signal("drift_started", drift_angle, slip_ratio)
		drift_timer = 0.0
		max_drift_angle = 0.0
	
	elif not is_drifting and was_drifting:
		emit_signal("drift_ended", drift_timer, max_drift_angle)
	
	if is_drifting:
		drift_timer += delta
		max_drift_angle = max(max_drift_angle, abs(drift_angle))
		emit_signal("drift_updated", drift_angle, slip_ratio, speed_kmh)

func calculate_drift_angle() -> float:
	var velocity_2d = Vector2(vehicle.local_velocity.x, vehicle.local_velocity.z)
	var car_forward = -vehicle.global_transform.basis.z
	var car_forward_2d = Vector2(car_forward.x, car_forward.z)
	
	return velocity_2d.normalized().angle_to(car_forward_2d.normalized())

func calculate_slip_ratio() -> float:
	var lateral = abs(vehicle.local_velocity.x)
	var longitudinal = abs(vehicle.local_velocity.z)
	return lateral / max(longitudinal, 0.1)
