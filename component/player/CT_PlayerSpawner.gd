extends Node
class_name CT_PlayerSpawner

@export var root: Node
@export var prefab: PackedScene

func _ready() -> void:
	SimusNetConnection.connect_network_node_callables(self,
	_net_ready,
	_net_disconnect,
	_net_not_connected
	)

func _net_ready() -> void:
	if SimusNetConnection.is_server():
		s_Users.on_connected.connect(_on_user_connected)
		s_Users.on_disconnected.connect(_on_user_disconnected)

func _net_disconnect() -> void:
	if SimusNetConnection.is_was_server():
		s_Users.on_connected.disconnect(_on_user_connected)
		s_Users.on_disconnected.disconnect(_on_user_disconnected)

func _net_not_connected() -> void:
	pass

func _on_user_connected(user: CT_User) -> void:
	var instance: Node = prefab.instantiate()
	user.set_in(instance)
	

func _on_user_disconnected(user: CT_User) -> void:
	pass
