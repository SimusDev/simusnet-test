extends Node

signal on_sync_started
signal on_sync_finished

@onready var CHANNEL_USERS: String = SimusNetChannels.register("users")
@onready var CHANNEL_INVENTORY: String = SimusNetChannels.register("inventory")
@onready var CHANNEL_INTERACTABLES: String = SimusNetChannels.register("interactables")
@onready var CHANNEL_STATES: String = SimusNetChannels.register("states")
@onready var CHANNEL_ENVIRONMENT: String = SimusNetChannels.register("environment")

@onready var CHANNEL_CONTENT: String = SimusNetChannels.register("content")

const MAX_PLAYERS: int = 1000
const DEFAULT_PORT: int = 8080
const CHUNK_SIZE: int = 32768

var server_info: CT_ServerInfo

static var server_broadcaster:SimusNetServerBroadcaster

func _ready() -> void:
	server_info = CT_ServerInfo.new()
	server_info.name = "server_info"
	add_child(server_info)
	
	SimusNetRPC.register(
		[receive_manifest_chunk, receive_file_chunk],
		SimusNetRPCConfig.new()
			.flag_set_channel(CHANNEL_CONTENT)
			.flag_set_reliable()
	)
	
	SimusNetRPC.register(
		[request_file],
		SimusNetRPCConfig.new()
			.flag_mode_to_server()
			.flag_set_channel(CHANNEL_CONTENT)
	)
	
	SimusNetEvents.event_connected.listen(_on_connected)
	SimusNetEvents.event_disconnected.listen(_on_disconnected)
	var commands_exec: Array[SD_ConsoleCommand] = [
		SD_ConsoleCommand.get_or_create("connect"),
		SD_ConsoleCommand.get_or_create("disconnect"),
		SD_ConsoleCommand.get_or_create("start.server"),
		SD_ConsoleCommand.get_or_create("start.dedicated")
	]
	
	for i in commands_exec:
		i.executed.connect(_on_cmd_executed.bind(i))
	
	if OS.has_feature("dedicated_server"):
		create_server(DEFAULT_PORT)

func _on_connected() -> void:
	SD_Console.i().write_info("connected to server.")
	
	if SimusNetConnection.is_server():
		if not multiplayer.peer_connected.is_connected(_on_peer_connected):
			multiplayer.peer_connected.connect(_on_peer_connected)

func _on_peer_connected(id: int):
	await get_tree().create_timer(0.5).timeout
	sync_content_to_peer(id)

func _on_disconnected() -> void:
	SD_Console.i().write_info("disconnected from server.")

func _on_cmd_executed(cmd: SD_ConsoleCommand) -> void:
	match cmd.get_code():
		"connect":
			connect_to_server_by_address(cmd.get_value())
		"disconnect":
			try_disconnect()
		"start.server":
			if cmd.get_arguments().size() < 1:
				cmd.get_console().write_error("please, set the port.")
				return
			create_server(cmd.get_value_as_int())
		"start.dedicated":
			if cmd.get_arguments().size() < 1:
				cmd.get_console().write_error("please, set the port.")
				return
			create_server(cmd.get_value_as_int(), true)

func try_disconnect() -> void:
	SimusNetConnection.try_close_peer()
	
	if is_instance_valid(server_broadcaster):
		server_broadcaster.queue_free()

func connect_to_server(ip: String, port: int = DEFAULT_PORT) -> void:
	SimusNetConnectionENet.create_client(ip, port)

func connect_to_server_by_address(address: String) -> void:
	var parsed: PackedStringArray = address.split(":")
	if parsed.size() == 2:
		connect_to_server(parsed[0], int(parsed[1]))
	return

func create_server(port: int = -1, dedicated: bool = false) -> void:
	if port < 0:
		var cfg_port = server_info._config.get_value("info", "port", -2)
		if cfg_port is int:
			port = cfg_port
		elif cfg_port is String:
			if cfg_port.is_valid_int():
				cfg_port = int(cfg_port)
		if port < 0:
			SimusDev.console.write_error("Failed to create server with this port %s" % port)
			return
	
	
	SimusNetConnection.set_dedicated_server(dedicated)
	SimusNetConnectionENet.create_server(port, MAX_PLAYERS)
	
	server_info._request_update_rpc()
	
	if is_instance_valid(server_broadcaster):
		if not server_info._config:
			return
	if !server_broadcaster:
		server_broadcaster = SimusNetServerBroadcaster.new()
	
	server_broadcaster.serverInfo = server_info.get_last().get_data()
	if not server_broadcaster.is_inside_tree():
		add_child(server_broadcaster)


#region SERVER (ОТПРАВКА)

func sync_content_to_peer(peer_id: int):
	on_sync_started.emit()
	var content_dir = server_info.get_last().get_content_path()
	var all_files = []
	
	var dir = DirAccess.open(content_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and not file_name.ends_with(".import"):
				all_files.append({"n": file_name, "h": FileAccess.get_md5(content_dir + file_name)})
			file_name = dir.get_next()
			
	SD_Console.i().write_info("Sending manifest to peer %d in chunks..." % peer_id)
	
	for i in range(0, all_files.size(), 40):
		var chunk = all_files.slice(i, i + 40)
		var is_last = (i + 40) >= all_files.size()
		SimusNetRPC.invoke_on(peer_id, receive_manifest_chunk, chunk, is_last)

func request_file(file_name: String):
	var peer_id = SimusNetRemote.sender_id
	var safe_name = file_name.get_file()
	var path = server_info.get_last().get_content_path() + safe_name
	
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var total_size = file.get_length()
		
		while file.get_position() < total_size:
			var pos = file.get_position()
			var data = file.get_buffer(CHUNK_SIZE)
			SimusNetRPC.invoke_on(peer_id, receive_file_chunk, safe_name, data, pos, total_size)
	else:
		SD_Console.i().write_error("File not found: " + safe_name)

#endregion

#region CLIENT

var local_content_path = "user://content/"
var _download_queue: Array[String] = []
var _temp_manifest: Array = []
var _file_buffers: Dictionary = {}

func receive_manifest_chunk(chunk: Array, is_last: bool):
	_temp_manifest.append_array(chunk)
	if is_last:
		_process_manifest()

func _process_manifest():
	_download_queue.clear()
	for item in _temp_manifest:
		var f_name = item["n"]
		var s_hash = item["h"]
		var l_path = local_content_path + f_name
		
		if not FileAccess.file_exists(l_path) or FileAccess.get_md5(l_path) != s_hash:
			_download_queue.append(f_name)
	
	_temp_manifest.clear()
	if _download_queue.size() > 0:
		SD_Console.i().write_info("Need to download %d files" % _download_queue.size())
		_request_next_from_queue()
	else:
		SD_Console.i().write_info("All content up to date.")
		on_sync_finished.emit()

func _request_next_from_queue():
	if _download_queue.size() > 0:
		SimusNetRPC.invoke_on_server(request_file, _download_queue[0])

func receive_file_chunk(file_name: String, data: PackedByteArray, offset: int, total_size: int):
	if not _file_buffers.has(file_name):
		_file_buffers[file_name] = PackedByteArray()
		_file_buffers[file_name].resize(total_size)
	
	for i in range(data.size()):
		_file_buffers[file_name][offset + i] = data[i]
	
	if offset + data.size() >= total_size:
		_finalize_file(file_name)

func _finalize_file(file_name: String):
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(local_content_path):
		dir.make_dir_recursive(local_content_path)
	
	var file = FileAccess.open(local_content_path + file_name, FileAccess.WRITE)
	if file:
		file.store_buffer(_file_buffers[file_name])
		file.close()
	
	_file_buffers.erase(file_name)
	SD_Console.i().write_info("Downloaded: " + file_name)
	
	if _download_queue.size() > 0:
		_download_queue.remove_at(0)
		
	if _download_queue.size() > 0:
		_request_next_from_queue()
	else:
		SD_Console.i().write_info("Sync complete!")
		on_sync_finished.emit()

#endregion
