@static_unload
extends RefCounted
class_name SimusNetConnectionENet

static func create_server(port: int, max_clients: int = 32) -> Error:
	SimusNetConnection.try_close_peer()
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, max_clients) 
	SimusNetConnection.set_peer(peer)
	return error

static func create_client(address: String, port: int) -> Error:
	SimusNetConnection.try_close_peer()
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, port)
	SimusNetConnection.set_peer(peer)
	return error
