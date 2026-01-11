extends Node

signal on_error(error: String)
signal on_success()

func _ready() -> void:
	SimusNetRPC.register([
		_request,
	], SimusNetRPCConfig.new().flag_mode_any_peer().
	flag_set_channel(Network.CHANNEL_USERS))
	
	SimusNetRPC.register([
		_receive_success,
		_receive_error,
	], SimusNetRPCConfig.new().flag_mode_server_only().
	flag_set_channel(Network.CHANNEL_USERS))

func request(login: String, password: String) -> void:
	var data: Dictionary = {
		"login": login,
		"password": password,
	}
	SimusNetRPC.invoke_on_server(_request, data)

func _request(user_input: Dictionary) -> void:
	var login: String = user_input.login
	var password: String = user_input.password
	
	if login.is_empty():
		return
	
	if password.is_empty():
		return
	
	var founded: CT_User = CT_User.server_find_by_login(login)
	
	if founded:
		SimusNetRPC.invoke_on(SimusNetRemote.sender_id, _receive_error, "error.user_already_online")
		return
	
	var data: R_LocalData = R_LocalData.get_or_create_server("users", user_input.login)
	if data.password != password:
		SimusNetRPC.invoke_on(SimusNetRemote.sender_id, _receive_error, "error.wrong_password")
		return
	
	var user: CT_User = CT_User.server_create(user_input)
	s_Users._connect_user(user)

func _receive_success() -> void:
	on_success.emit()

func _receive_error(err: String) -> void:
	on_error.emit(err)
