@tool
extends Node3D
class_name CT_PlayerNickname3D

const SCENE: PackedScene = preload("res://component/player/player_nickname.tscn")

func _ready() -> void:
	if SimusNet.is_network_authority(self):
		queue_free()
		return
	
	await get_tree().process_frame
	var i: Node = SCENE.instantiate()
	i.set_multiplayer_authority(get_multiplayer_authority(), false)
	add_child(i)
