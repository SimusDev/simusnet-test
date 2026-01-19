class_name PlayerUI extends Control

var _local:PlayerUI

func get_local() -> PlayerUI:
	return _local

func _ready() -> void:
	if SimusNet.is_network_authority(self):
		_local = self
	
	for ui: R_UI in R_UI.get_ui_list():
		if not ui.global:
			continue
		
		if ui.prefab:
			var instance: Node = ui.prefab.instantiate()
			ui._instance = instance
			ui.on_instance_set.emit()
			add_child(instance)
			move_child(instance, 0)
