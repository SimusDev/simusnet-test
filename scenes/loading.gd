extends Control

func _ready() -> void:
	s_GameObjects.clear_registry()
	await s_GameObjects.async_load_directory(R_GameSettings.instance().objects_path)
	start()

func start() -> void:
	s_SceneChanger.set_ingame_state(true)
	get_tree().change_scene_to_file.call_deferred("res://scenes/game.tscn")
