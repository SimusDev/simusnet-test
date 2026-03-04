class_name W_Game extends Node3D

@export var infinity_ammo:bool = false

static var instance:W_Game = null
static func i() -> W_Game:
	return instance

func _init() -> void:
	if not instance:
		instance = self
	
	randomize()
