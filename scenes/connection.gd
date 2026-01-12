extends Control

func _ready() -> void:
	visible = !SimusNetConnection.is_active()
	SimusNetEvents.event_connected.listen(set_visible.bind(false))
	SimusNetEvents.event_disconnected.listen(set_visible.bind(true))

func _on__server_pressed() -> void:
	SimusNetConnectionENet.create_server(8080)

func _on__client_pressed() -> void:
	SimusNetConnectionENet.create_client("localhost", 8080)
