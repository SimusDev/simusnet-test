extends Node
class_name CT_User

var _peer: int = -1

static var _dictionary: Dictionary[int, CT_User]
static var _list: Array[CT_User]

var _server_data: R_LocalData

var _synced_data_last: Dictionary = {}
var _right_list: PackedStringArray

var _nickname: String = ""

signal on_nickname_changed()
signal on_avatar_changed()

signal on_right_added(right: PackedStringArray)
signal on_right_removed(right: PackedStringArray)
signal on_rights_updated()

static var _local: CT_User

var _node: Node

func get_avatar() -> Texture:
	return load("res://icon.svg")

func get_player_node() -> Node:
	if !is_instance_valid(_node):
		_node = null
	return _node

func set_in(node: Node) -> CT_User:
	node.set_meta("CT_User", self)
	_node = node
	return self

static func find_in(node: Node) -> CT_User:
	if !node:
		return null
	
	if node.has_meta("CT_User"):
		var value: Variant = node.get_meta("CT_User")
		if !is_instance_valid(value):
			node.set_meta("CT_User", null)
		return node.get_meta("CT_User")
	return null

static func find_above(node: Node) -> CT_User:
	if !node:
		return null
	
	var user: CT_User = find_in(node)
	if user:
		return user
	return find_above(node.get_parent())

static func get_local() -> CT_User:
	return _local

func is_local() -> bool:
	return self == _local

func server_get_login() -> String:
	return _server_data.get_value_or_add("login", "user")

func server_get_password() -> String:
	return _server_data.get_value("password", "")

static func find_by_nickname(nick: String) -> CT_User:
	for i in get_list():
		if i.get_nickname() == nick:
			return i
	return null

static func server_find_by_login(login: String) -> CT_User:
	for i in _list:
		if i.server_get_login() == login:
			return i
	return null

static func find_by_peer(peer: int) -> CT_User:
	return _dictionary.get(peer)

func get_nickname() -> String:
	return _nickname

func get_server_data() -> R_LocalData:
	return _server_data

static func get_dictionary() -> Dictionary[int, CT_User]:
	return _dictionary

static func get_list() -> Array[CT_User]:
	return _list

func get_peer() -> int:
	return _peer

func _ready() -> void:
	set_multiplayer_authority(SimusNet.SERVER_ID)
	if _peer == SimusNetConnection.get_unique_id():
		_local = self
	
	SimusNetRPC.register(
		[
			_right_remove_or_add_rpc,
		], SimusNetRPCConfig.new().flag_mode_to_server().
		flag_set_channel(Network.CHANNEL_USERS)
	)
	
	SimusNetRPC.register(
		[
			_receive_remove_or_add_right,
		], SimusNetRPCConfig.new().flag_mode_server_only().
		flag_set_channel(Network.CHANNEL_USERS)
	)

func is_admin() -> bool:
	return get_right_list().has("admin") or is_developer()

func is_developer() -> bool:
	return get_right_list().has("dev")

func get_right_list() -> PackedStringArray:
	return _right_list

func try_give_rights(list: PackedStringArray) -> bool:
	if !get_local():
		return false
	
	if get_local().is_admin():
		SimusNetRPC.invoke_on_server(_right_remove_or_add_rpc, list, false)
	return get_local().is_admin()

func try_remove_rights(list: PackedStringArray) -> bool:
	if !get_local():
		return false
	
	if get_local().is_admin():
		SimusNetRPC.invoke_on_server(_right_remove_or_add_rpc, list, true)
	return get_local().is_admin()

func _right_remove_or_add_rpc(list: PackedStringArray, remove: bool) -> void:
	if SimusNetRemote.sender_id != get_peer():
		return
	
	if is_developer() and get_peer() != SimusNetRemote.sender_id:
		return
	
	if is_admin() or get_peer() == SimusNet.SERVER_ID:
		
		for r in list:
			SimusNetRPC.invoke_all(_receive_remove_or_add_right, r, remove)

func _receive_remove_or_add_right(right: String, remove: bool) -> void:
	if remove:
		if get_right_list().has(right):
			_right_list.erase(right)
			on_right_removed.emit(right)
	else:
		if !get_right_list().has(right):
			_right_list.append(right)
			on_right_added.emit(right)
	
	on_rights_updated.emit()

func _enter_tree() -> void:
	_dictionary[get_peer()] = self
	_list.append(self)

func _exit_tree() -> void:
	_dictionary.erase(get_peer())
	_list.erase(self)

func serialize() -> Dictionary:
	var data: Dictionary = {}
	data[0] = get_peer()
	data[1] = get_nickname()
	data[2] = _right_list
	return data

static func deserialize(data: Dictionary) -> CT_User:
	var user := CT_User.new()
	user._peer = data[0]
	user._nickname = data[1]
	user.name = str(data[0])
	user._right_list = data[2]
	return user

func serialize_reference() -> int:
	return _peer

static func deserialize_reference(data: int) -> CT_User:
	return find_by_peer(data)

static func server_create(user_input: Dictionary, peer: int) -> CT_User:
	var user := CT_User.new()
	user._peer = peer
	var data: R_LocalData = R_LocalData.get_or_create_server("users", user_input.login)
	user._server_data = data
	data.get_value_or_add("login", user_input.login)
	data.get_value_or_add("password", user_input.password)
	user._nickname = data.get_value_or_add("nickname", user_input.login)
	user.name = str(peer)
	user._right_list = data.get_value_or_add("right_list", PackedStringArray())
	data.save()
	return user
