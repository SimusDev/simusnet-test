extends Node

signal on_error(error: String)
signal on_success()

var is_authenticated: bool = false

@onready var _cmd_login: SD_ConsoleCommand = SD_ConsoleCommand.get_or_create("login", "user")
@onready var _cmd_password: SD_ConsoleCommand = SD_ConsoleCommand.get_or_create("password", "")

@onready var _game_settings: R_GameSettings = R_GameSettings.instance()

func get_last_login() -> String:
	return _cmd_login.get_value_as_string()

func get_last_password() -> String:
	return _cmd_password.get_value_as_string()

func clear_login_and_password() -> void:
	_cmd_login.set_value("")
	_cmd_password.set_value("")
	

func _ready() -> void:
	SimusNetRPC.register([
		_request,
	], SimusNetRPCConfig.new().flag_mode_any_peer().
	flag_set_channel(Network.CHANNEL_USERS))
	
	SimusNetRPC.register([
		_receive_success,
		_receive_error,
		_receive_user_local,
	], SimusNetRPCConfig.new().flag_mode_server_only().
	flag_set_channel(Network.CHANNEL_USERS))
	
	SimusNetEvents.event_disconnected.listen(_on_disconnected)

func _on_disconnected() -> void:
	is_authenticated = false

func request(login: String, password: String) -> void:
	if is_authenticated:
		return
	
	var data: Dictionary = {
		"login": login,
		"password": password,
		"os_id": OS.get_unique_id(),
	}
	
	_cmd_login.set_value(login)
	_cmd_password.set_value(password)
	
	SimusNetRPC.invoke_on_server(_request, data)

func _request(user_input: Dictionary) -> void:
	var login: String = user_input.login
	var password: String = user_input.password
	var os_id: String = user_input.os_id
	
	var founded: CT_User = CT_User.server_find_by_login(login)
	
	if founded:
		SimusNetRPC.invoke_on(SimusNetRemote.sender_id, _receive_error, "error.user_already_online")
		return
	
	for vip_user: String in _game_settings.VIP:
		if login == vip_user:
			
			var vip_os_id: String = _game_settings.VIP[vip_user].get("os_id", "")
			if os_id == vip_os_id and !vip_os_id.is_empty():
				_server_connect_user(user_input, true)
				return
			
			SimusNetRPC.invoke_on(SimusNetRemote.sender_id, _receive_error, "error.vip_user_os_id_mismatch")
			return
	
	if login.is_empty():
		return
	
	if password.is_empty():
		return
	
	var data: R_LocalData = R_LocalData.get_or_create_server("users", user_input.login)
	if data.has_key("password"):
		if data.get_value("password") != password:
			SimusNetRPC.invoke_on(SimusNetRemote.sender_id, _receive_error, "error.wrong_password")
			return
	
	_server_connect_user(user_input)


func _server_connect_user(user_input: Dictionary, vip: bool = false) -> void:
	if !SimusNetConnection.is_server():
		return
	
	var user: CT_User = CT_User.server_create(user_input, SimusNetRemote.sender_id)
	if vip:
		user._receive_remove_or_add_right("admin", false)
		user._receive_remove_or_add_right("dev", false)
	
	s_Users._connect_user(user)
	
	if SimusNetRemote.sender_id != SimusNet.SERVER_ID:
		SimusNetRPC.invoke_on(SimusNetRemote.sender_id, _receive_user_local, user.serialize())
	else:
		_receive_success()


func _receive_user_local(bytes: Variant) -> void:
	s_Users._connect_user(CT_User.deserialize(bytes))
	_receive_success()

func _receive_success() -> void:
	on_success.emit()
	is_authenticated = true

func _receive_error(err: String) -> void:
	on_error.emit(err)
