extends Control

@onready var _icon: TextureRect = $Icon
@onready var _description: RichTextLabel = $Description
@onready var _name: Label = $Name
@onready var _user_count: RichTextLabel = $UserCount
@onready var _ping: RichTextLabel = $Ping

@onready var join: Button = $CenterContainer/HBoxContainer/Join

@onready var _disable_input_ui: Panel = $_DisableInputUI
@onready var _disabled_label: Label = $_DisableInputUI/_DisabledLabel

var server_uri:String 

func _ready() -> void:
	_description.text = ""
	_name.text = ""
	
	Network.server_info.on_update_received.connect(_on_update_received)
	
	SimusNetEvents.event_disconnected.listen(_disconnected)
	SimusNetEvents.event_connecting.listen(_connecting)
	SimusNetEvents.event_connected.listen(_connected)
	
	if SimusNetConnection.is_active():
		_connected()
	else:
		_disconnected()
	
	

func _on_update_received() -> void:
	var info: R_ServerInfo = Network.server_info.get_last()
	if !is_instance_valid(info):
		return
	
	_description.text = info.get_description()
	_name.text = info.get_name()
	_user_count.text = "%sms" % info.get_ping()
	_user_count.text = "%s/%s" % [ info.get_players().size(), info.get_max_players() ]
	
	server_uri = info.get_website()
	var image: ImageTexture = info.get_image()
	if image:
		_icon.texture = image

func _disconnected() -> void:
	_disable_input_ui.show()
	_disabled_label.text = ""

func _connecting() -> void:
	_disconnected()
	show()
	_disabled_label.text = "Connecting..."

func _connected() -> void:
	join.visible = !s_SceneChanger.is_ingame_state()
	_disable_input_ui.hide()
	
	if !s_SceneChanger.is_ingame_state() or SimusNetConnection.is_server():
		Network.server_info.request_update()
	
	_on_update_received()

func _on_join_pressed() -> void:
	if s_SceneChanger.is_ingame_state():
		return
	
	s_SceneChanger.queue_change_scene_with_base_path("loading")

func _on_quit_pressed() -> void:
	SimusNetConnection.try_close_peer()

func _on_web_pressed() -> void:
	OS.shell_open(server_uri)
