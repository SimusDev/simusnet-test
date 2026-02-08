extends R_WorldObject
class_name R_Ammo

@export var base_damage: float = 35.0

@export_group("Ballistics")
@export var muzzle_velocity: float = 850.0 
@export_range(0.0, 1.0, 0.00001) var air_friction: float = 0.0005 
@export_range(0.00001, 1.0, 0.00001) var mass: float = 0.008 

@export_group("Penetration")
@export var penetration_power: float = 30.0 
@export var ricochet_chance: float = 0.5 
@export var dispersion_after_penetration: float = 2.0 

func _get_group() -> String:
	return "ammo"
