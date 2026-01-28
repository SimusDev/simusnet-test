class_name VehicleSkidDetector extends Node

@export var vehicle: Vehicle
@export var lateral_slip_threshold := 0.5
@export var longitudinal_slip_threshold := 1.0

var skid_wheels:Array[Wheel]

func is_wheel_skid(wheel: Wheel) -> bool:
	if not wheel.is_colliding(): return false

	var forward_dir = wheel.global_transform.basis.z
	var velocity_dir = wheel.local_velocity.normalized()
	var side_slip = abs(wheel.local_velocity.x)
	
	var wheel_rolling_speed = wheel.spin * wheel.tire_radius
	var longitudinal_slip = abs(wheel_rolling_speed - wheel.local_velocity.z)

	return side_slip > lateral_slip_threshold or longitudinal_slip > longitudinal_slip_threshold


func is_skid() -> bool:
	return skid_wheels.size() > 0

func get_skid_intensity() -> float:
	var max_i = 0.0
	for wheel in vehicle.wheel_array:
		if not wheel.is_colliding(): continue
		
		var lat = abs(wheel.slip_vector.x) / lateral_slip_threshold
		var lon = abs(wheel.slip_vector.y) / longitudinal_slip_threshold
		var current_wheel_i = max(lat, lon)
		
		max_i = max(max_i, current_wheel_i)
		
	return clamp(max_i, 0.0, 1.0)

func _process(_delta):
	if not vehicle:
		return
	
	for wheel in vehicle.wheel_array:
		if is_wheel_skid(wheel):
			skid_wheels.append(wheel)
		else:
			skid_wheels.erase(wheel)
