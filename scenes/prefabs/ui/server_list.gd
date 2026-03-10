extends Control

@export var server_item:PackedScene

@export var server_listener:SimusNetServerListener
@export var container:Container

func _ready() -> void:
	server_listener.server_discovered.connect(_append_server_to_list)

func _append_server_to_list(server_info:Dictionary) -> void:
	var new_server:Control = server_item.instantiate()
	
	new_server.set("server_listener", server_listener)
	new_server.set("server_info", server_info)
	
	container.add_child(new_server)
