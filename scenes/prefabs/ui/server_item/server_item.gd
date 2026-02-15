extends Button

var info:Dictionary
var server_ip_addr:String
var server_port:int
var server_listener:SimusNetServerListener

@onready var server_name: Label = $ServerName
@onready var description: RichTextLabel = $Description


func _ready() -> void:
	server_name.text = info.get("name", "<empty_name>")
	description.text = server_ip_addr + ":" + str(server_port)
	if server_listener:
		server_listener.remove_server.connect(queue_free)

func _pressed() -> void:
	Network.connect_to_server(server_ip_addr, server_port)
