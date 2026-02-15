extends Button

var info:Dictionary
var server_ip_addr:String
var server_port:int
var server_listener:SimusNetServerListener

@onready var server_name: RichTextLabel = $ServerName
@onready var description: RichTextLabel = $Description


func _ready() -> void:
	server_name.text = info.get("name", "<empty_name>")
	description.text = info.get("description", "<empty_description>")
	if server_listener:
		server_listener.server_removed.connect(_on_server_removed)

func _on_server_removed(ip:String) -> void:
	if ip == server_ip_addr:
		queue_free()

func _pressed() -> void:
	Network.connect_to_server(server_ip_addr, server_port)
