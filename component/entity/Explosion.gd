extends RefCounted
class_name Explosion

var _scale: float = 1.0
var _strength: float = 1.0

var _level: LevelInstance

var _global_position: Vector3 = Vector3.ZERO

const OBJECT: R_WorldObject = preload("res://src/objects/entity/explosion.tres")

func _init(level: LevelInstance, global_position: Variant) -> void:
	_level = level
	_global_position = LevelInstance.get_global_position_from(global_position)

func set_scale(value: float) -> Explosion:
	_scale = value
	return self

func set_strength(value: float) -> Explosion:
	_strength = value
	return self

func _explode(local: bool) -> Explosion:
	var instance: Node3D
	if local:
		instance = I_WorldObject.new(_level, OBJECT).instantiate_local().get_instance()
	else:
		instance = I_WorldObject.new(_level, OBJECT).instantiate().get_instance()
	
	instance._scale = _scale
	instance._strength = _strength
	instance.global_position = _global_position
	return self

func explode() -> Explosion:
	return _explode(false)

func explode_local() -> Explosion:
	return _explode(true)
