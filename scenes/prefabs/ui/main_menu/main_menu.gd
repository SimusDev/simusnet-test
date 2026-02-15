extends Control

@export var ingame: bool = false
@export var _button_container: Array[Control] = []
@export var _screens_container: Control
@export var _popups_container: Control

@onready var _connect_to_server_: LineEdit = $Panel/MarginContainer/ScreenConnect/LineEdit

@export var _hide_ingame: Array[CanvasItem]
@export var _show_ingame: Array[CanvasItem]

func _ready() -> void:
	_connect_to_server_.text = SD_ConsoleCommand.get_or_create("last_address", "localhost:8080").get_value_as_string()
	
	$Devs.text = "by %s" % SD_EngineSettings.create_or_get().developer
	$version.text = ProjectSettings.get_setting("application/config/version")
	
	for _container in _button_container:
		for child in _container.get_children():
			if child is Button:
				child.pressed.connect(_on_button_pressed.bind(child))
	
	_switch_buttons_screen("ScreenMain")
	
	if ingame:
		for i in _hide_ingame:
			i.hide()
		for i in _show_ingame:
			i.show()
		
		_switch_popup("ServerInfo")

func _switch_buttons_screen(_name: String) -> void:
	SD_Nodes.set_children_visibility(_screens_container, false)
	_screens_container.get_node(_name).visible = true

func _switch_popup(_name: String, hide_prev:bool = false) -> void:
	if hide_prev:
		SD_Nodes.set_children_visibility(_popups_container, false)
	_popups_container.get_node(_name).visible = true

func _on_button_pressed(button: Button) -> void:
	match button.name:
		"Disconnect":
			Network.try_disconnect()
		"Play":
			Network.create_server()
		"Multiplayer":
			_switch_popup("ServerList")
			_switch_buttons_screen("ScreenConnect")
		"ConnectToServer":
			Network.connect_to_server_by_address(_connect_to_server_.text)
			SD_ConsoleCommand.get_or_create("last_address").set_value(_connect_to_server_.text)
			#Simus
			
		"Load Game":
			pass
		"Save Game":
			pass
		"Settings":
			_switch_popup("Settings")
		"Server":
			_switch_popup("ServerInfo")
		"BackToMain":
			_switch_buttons_screen("ScreenMain")
