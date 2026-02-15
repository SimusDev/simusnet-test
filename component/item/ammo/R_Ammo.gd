extends R_WorldObject
class_name R_Ammo

@export var prefab_override: PackedScene

@export var base_damage: float = 35.0

@export_group("Ballistics")
@export var muzzle_velocity: float = 850.0 
@export_range(0.0, 1.0, 0.000001) var air_friction: float = 0.0005 
@export_range(0.000001, 1.0, 0.000001) var mass: float = 0.008 

@export_group("Penetration")
@export var penetration_power: float = 30.0 
@export var ricochet_chance: float = 0.5 
@export var dispersion_after_penetration: float = 2.0 

@export_group("Explosive")
@export var explosive: bool = false
@export var explosive_scale: float = 1.0
@export var explosive_strength: float = 1.0

const DEFAULT_PREFAB: PackedScene = preload("res://scenes/prefabs/firearm_bullet.tscn")

func get_prefab() -> PackedScene:
	if prefab_override:
		return prefab_override
	return DEFAULT_PREFAB

func _get_group() -> String:
	return "ammo"
