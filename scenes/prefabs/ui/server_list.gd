extends Control

@export var server_item:PackedScene
@onready var server_listener: SimusNetServerListener = $SimusNetServerListener
@onready var v_box_container: VBoxContainer = $ScrollContainer/VBoxContainer

func _ready() -> void:
	_clean()
	server_listener.new_server.connect(_on_new_server)

func _clean() -> void:
	SD_Nodes.clear_all_children(v_box_container)

func _on_new_server(data:Dictionary, server_ip_addr:String, server_port:int) -> void:
	var new_server_item = server_item.instantiate()
	new_server_item.server_ip_addr = server_ip_addr
	new_server_item.server_port = server_port
	new_server_item.info = data
	new_server_item.server_listener = server_listener
	v_box_container.add_child(new_server_item)
