extends Control

@export var _button_container: Array[Control] = []
@export var _screens_container: Control

@onready var _connect_to_server_: LineEdit = $Panel/MarginContainer/ScreenConnect/LineEdit

func _ready() -> void:
	_connect_to_server_.text = SD_ConsoleCommand.get_or_create("last_address", "localhost:8080").get_value_as_string()
	
	$Devs.text = "Devs: %s" % SD_EngineSettings.create_or_get().developer
	
	for _container in _button_container:
		for child in _container.get_children():
			if child is Button:
				child.pressed.connect(_on_button_pressed.bind(child))
	
	_switch_buttons_screen("ScreenMain")

func _switch_buttons_screen(_name: String) -> void:
	SD_Nodes.set_children_visibility(_screens_container, false)
	_screens_container.get_node(_name).visible = true

func _on_button_pressed(button: Button) -> void:
	match button.name:
		"Play":
			Network.create_server()
		"Multiplayer":
			_switch_buttons_screen("ScreenConnect")
		"ConnectToServer":
			Network.connect_to_server_by_address(_connect_to_server_.text)
			SD_ConsoleCommand.get_or_create("last_address").set_value(_connect_to_server_.text)
		"Load Game":
			pass
		"Save Game":
			pass
		"Settings":
			_switch_buttons_screen("ScreenSettings")
		"BackToMain":
			_switch_buttons_screen("ScreenMain")
