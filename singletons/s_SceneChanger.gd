extends SD_GameSceneChanger

func _ready() -> void:
	SimusNetEvents.event_connected.listen(_on_network_connected)
	SimusNetEvents.event_disconnected.listen(_on_network_disconnected)

func _on_network_connected() -> void:
	queue_change_scene_with_base_path("loading", false)

func _on_network_disconnected() -> void:
	queue_change_scene_with_base_path("menu", false)
