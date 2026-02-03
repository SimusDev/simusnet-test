extends R_WorldObject
class_name R_Ammo

@export var damage_multiplier: float = 1.0

func _get_group() -> String:
	return "ammo"
