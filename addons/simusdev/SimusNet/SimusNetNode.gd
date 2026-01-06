@icon("./icons/MultiplayerSynchronizer.svg")
extends Node
class_name SimusNetNode

signal on_network_ready()
signal on_network_disconnect()
signal on_network_not_connected()

var is_network_ready: bool = false

func _ready() -> void:
	SimusNetConnection.connect_network_node_callables(self,
	_network_ready,
	_network_disconnect,
	_network_not_connected
	)

func _network_ready() -> void:
	is_network_ready = true
	on_network_ready.emit()

func _network_disconnect() -> void:
	is_network_ready = false
	on_network_disconnect.emit()

func _network_not_connected() -> void:
	on_network_not_connected.emit()

func is_server() -> bool:
	return SimusNetConnection.is_server()

func is_dedicated_server() -> bool:
	return SimusNetConnection.is_dedicated_server()
