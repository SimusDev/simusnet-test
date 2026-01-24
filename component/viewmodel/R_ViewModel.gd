@tool
extends Resource
class_name R_ViewModel

@export var world: PackedScene : get = get_world
@export var view: PackedScene
@export var player: PackedScene

enum TYPE {
	WORLD,
	VIEW,
	PLAYER,
}

func get_world() -> PackedScene:
	if !world:
		world = load("uid://bnao0ejkdk8a5")
	return world

func pick_prefab(from_type: TYPE) -> PackedScene:
	match from_type:
		TYPE.VIEW:
			return view
		TYPE.PLAYER:
			return player
	return world
