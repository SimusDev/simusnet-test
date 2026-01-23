extends Resource
class_name R_ViewModel

@export var world: PackedScene : get = get_world
@export var view: PackedScene
@export var player: PackedScene

func get_world() -> PackedScene:
	if !world:
		world = load("uid://bnao0ejkdk8a5")
	return world
