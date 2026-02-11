extends RefCounted
class_name Explosion

var _scale: float = 1.0
var _strength: float = 1.0

var _level: LevelInstance

const OBJECT: R_WorldObject = preload("res://src/objects/entity/explosion.tres")

func _init(level: LevelInstance) -> void:
	_level = level

func set_scale(value: float) -> Explosion:
	_scale = value
	return self

func set_strength(value: float) -> Explosion:
	_strength = value
	return self

func explode() -> Explosion:
	var instance: Node3D = I_WorldObject.new(_level, OBJECT).instantiate().get_instance()
	instance._scale = _scale
	instance._strength = _strength
	return self
