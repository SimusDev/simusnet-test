extends Control

func _ready() -> void:
	await s_GameObjects.async_load_directory(R_GameSettings.instance().objects_path)
	start()

func start() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/game.tscn")
