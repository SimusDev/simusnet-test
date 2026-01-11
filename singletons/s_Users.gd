extends Node

signal on_connected(user: CT_User)
signal on_disconnected(user: CT_User)

func _ready() -> void:
	SimusNetConnection.connect_network_node_callables(self, 
	_network_ready, _network_disconnect, _network_not_connected)
	
	SimusNetEvents.event_peer_disconnected.listen(_on_peer_disconnected, true)
	
	

func _network_ready() -> void:
	SimusNetRPC.invoke_on_server(_send)

func _send() -> void:
	var data: Array = []
	for i in CT_User.get_list():
		data.append(i.serialize())
	SimusNetRPC.invoke_on(SimusNetRemote.sender_id, _receive, SimusNetCompressor.parse(data))

func _receive(bytes: PackedByteArray) -> void:
	var data: Array = SimusNetDecompressor.parse(bytes)
	for i in data:
		_connect_user(CT_User.deserialize(i), false)

func _network_disconnect() -> void:
	for i in CT_User.get_list():
		i.queue_free()

func _network_not_connected() -> void:
	pass

func _connect_user(user: CT_User, emit_signals: bool = true) -> void:
	if user.is_inside_tree():
		return
	
	if emit_signals:
		on_connected.emit(user)
		SD_Console.i().write_warning("%s connected." % user.get_nickname())
	
	add_child(user)

func _on_peer_disconnected(event: SimusNetEvent) -> void:
	var user: CT_User = CT_User.find_by_peer(event.get_arguments())
	if user:
		_disconnect_user(user)

func _disconnect_user(user: CT_User, emit_signals: bool = true) -> void:
	if !user.is_inside_tree():
		return
	
	if emit_signals:
		on_disconnected.emit(user)
		SD_Console.i().write_warning("%s disconnected." % user.get_nickname())
	
	user.queue_free()
