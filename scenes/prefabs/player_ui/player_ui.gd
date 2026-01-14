class_name PlayerUI extends Control

var _local:PlayerUI

func get_local() -> PlayerUI:
	return _local

func _ready() -> void:
	if SimusNet.is_network_authority(self):
		_local = self
