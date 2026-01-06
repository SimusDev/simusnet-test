extends RefCounted
class_name SimusNetLogger

var _begin: String 

var enabled: bool = true

static func create_for(name: String) -> SimusNetLogger:
	var logger := SimusNetLogger.new()
	logger._begin = name
	return logger

func _get_begin() -> String:
	var text: String = "[%s] %s: "
	if SimusNetConnection.is_server():
		return text % ["SERVER", _begin]
	return text % ["CLIENT", _begin]

func debug(...args: Array) -> void:
	if enabled:
		print(_get_begin(), args)

func debug_error(...args: Array) -> void:
	if enabled:
		printerr(_get_begin(), args)

func push_error(...args: Array) -> void:
	if enabled:
		push_error(_get_begin(), args)

func push_warning(...args: Array) -> void:
	if enabled:
		push_warning(_get_begin(), args)
