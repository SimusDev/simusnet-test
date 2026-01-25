extends Node
class_name CT_User

var _peer: int = -1

static var _dictionary: Dictionary[int, CT_User]
static var _list: Array[CT_User]

var _server_data: R_LocalData

var _nickname: String = ""

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
	return data

static func deserialize(data: Dictionary) -> CT_User:
	var user := CT_User.new()
	user._peer = data[0]
	user._nickname = data[1]
	user.name = str(data[0])
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
	data.save()
	return user
