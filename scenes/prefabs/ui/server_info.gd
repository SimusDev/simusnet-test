extends Control

@onready var _icon: TextureRect = $Icon
@onready var _description: RichTextLabel = $Description
@onready var _name: Label = $Name

@onready var _disable_input_ui: Panel = $_DisableInputUI
@onready var _disabled_label: Label = $_DisableInputUI/_DisabledLabel

var _received_info: R_ServerInfo

func _ready() -> void:
	_description.text = ""
	_name.text = ""
	
	SimusNetEvents.event_disconnected.listen(_disconnected)
	SimusNetEvents.event_connecting.listen(_connecting)
	SimusNetEvents.event_connected.listen(_connected)
	
	if SimusNetConnection.is_active():
		_connected()
	else:
		_disconnected()
	
	Network.server_info.on_update_received.connect(_on_update_received)

func _on_update_received(info: R_ServerInfo) -> void:
	_received_info = info
	_description.text = info.get_description()
	_name.text = info.get_name()

func _disconnected() -> void:
	_disable_input_ui.show()
	_disabled_label.text = ""

func _connecting() -> void:
	_disconnected()
	show()
	_disabled_label.text = "Connecting..."

func _connected() -> void:
	_disable_input_ui.hide()
	Network.server_info.request_update()

func _on_disconnect_pressed() -> void:
	SimusNetConnection.try_close_peer()

func _on_join_pressed() -> void:
	s_SceneChanger.queue_change_scene_with_base_path("loading")

func _on_quit_pressed() -> void:
	pass # Replace with function body.
