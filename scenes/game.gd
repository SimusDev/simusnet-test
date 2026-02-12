extends Node3D

func _init() -> void:
	randomize()

func _ready() -> void:
	s_SceneChanger.states.set("ingame", true)
