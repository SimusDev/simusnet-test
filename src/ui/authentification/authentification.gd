extends Control

@export var _line_login: LineEdit
@export var _line_password: LineEdit
@export var _message: Label

func _ready() -> void:
	_line_login.text = s_Authentication.get_last_login()
	_line_password.text = s_Authentication.get_last_password()
	s_Authentication.on_error.connect(_on_error)
	s_Authentication.on_success.connect(queue_free)

func _on_error(error: String) -> void:
	_message.text = error

func _on_enter_pressed() -> void:
	s_Authentication.request(_line_login.text, _line_password.text)
