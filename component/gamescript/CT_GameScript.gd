extends Node
class_name CT_GameScript

func get_handler() -> CT_GameScriptHandler:
	return get_parent() as CT_GameScriptHandler

func _initialize() -> void:
	if is_instance_valid(PlayerUI.get_local()):
		_ui_ready(PlayerUI.get_local())
		return
	
	PlayerUI.on_ready.add_listener(_on_player_ui_ready)

func _on_player_ui_ready() -> void:
	_ui_ready(PlayerUI.get_local())

func _ui_ready(ui: PlayerUI) -> void:
	pass
