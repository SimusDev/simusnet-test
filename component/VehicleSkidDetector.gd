class_name VehicleSkidDetector extends Node

@export var vehicle: Vehicle
@export var lateral_skid_threshold := 0.3
@export var longitudinal_skid_threshold := 0.5

var skid_wheels:Array[Wheel]

func is_wheel_skid(wheel: Wheel) -> bool:
	if not wheel.is_colliding():
		return false

	var vehicle_speed := vehicle.linear_velocity.length()
	
	if vehicle_speed < 0.5:
		return abs(wheel.slip_vector.x) > lateral_skid_threshold

	return abs(wheel.slip_vector.x) > lateral_skid_threshold or \
		   abs(wheel.slip_vector.y) > longitudinal_skid_threshold

func is_skid() -> bool:
	return skid_wheels.size() > 0

func get_skid_intensity() -> float:
	var intensity := 0.0
	for wheel in vehicle.wheel_array:
		if not wheel.is_colliding():
			continue
		var lat_slip = abs(wheel.slip_vector.x) / lateral_skid_threshold
		var long_slip = abs(wheel.slip_vector.y) / longitudinal_skid_threshold
		var wheel_intensity = max(lat_slip, long_slip)
		intensity += wheel_intensity
	return min(intensity / 4.0, 1.0) 

func _process(_delta):
	if not vehicle:
		return
	
	for wheel in vehicle.wheel_array:
		if is_wheel_skid(wheel):
			skid_wheels.append(wheel)
		else:
			skid_wheels.erase(wheel)
