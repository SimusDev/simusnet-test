extends Control

@export var server_item:PackedScene
@onready var server_listener: SimusNetServerListener = $SimusNetServerListener
@onready var v_box_container: VBoxContainer = $ScrollContainer/VBoxContainer

func _ready() -> void:
	_clean()
	server_listener.server_discovered.connect(_on_new_server)

func _clean() -> void:
	SD_Nodes.clear_all_children(v_box_container)

func _on_new_server(data:Dictionary) -> void:
	var new_server_item = server_item.instantiate()
	new_server_item.server_ip_addr = data["ip"]
	new_server_item.server_port = data["port"]
	new_server_item.info = data
	new_server_item.server_listener = server_listener
	v_box_container.add_child(new_server_item)
