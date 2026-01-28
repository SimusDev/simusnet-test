extends Node

@export var ip: String = ""
@export var port: int = 0
@export var packet_count: int = 2000
@export var packet: String = "SPAM"

var _socket: PacketPeerUDP

signal on_connected()

func _ready() -> void:
	_socket = PacketPeerUDP.new()
	var err: Error = _socket.connect_to_host(ip, port)
	if err == OK:
		print("connected to server: %s:%s" % [ip, port])
		on_connected.emit()
	
	set_process(err == OK)

func _process(delta: float) -> void:
	for i in packet_count:
		var fake_message: String = packet + str(randi())
		_socket.put_var(fake_message)
