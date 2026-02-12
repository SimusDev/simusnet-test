extends SD_GameSceneChanger

var states: Dictionary = {}

func _ready() -> void:
	SimusNetEvents.event_connected.listen(_on_network_connected)
	SimusNetEvents.event_disconnected.listen(_on_network_disconnected)

func _on_network_connected() -> void:
	if SimusNetConnection.is_server():
		queue_change_scene_with_base_path("loading", false)

func _on_network_disconnected() -> void:
	if states.get("ingame", false) == true:
		queue_change_scene_with_base_path("menu", false)
		states.set("ingame", false)
