extends SD_GameSceneChanger

func _ready() -> void:
	SimusNetEvents.event_connected.listen(_on_network_connected)

func _on_network_connected() -> void:
	queue_change_scene_with_base_path("loading", false)
