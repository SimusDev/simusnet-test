class_name CT_Tick extends Node

signal tick

@export var tickrate:float = 30.0 :
	set(val):
		tickrate = val
		_update_timer()

@export var server_authority:bool = false

var _timer:Timer

func _ready() -> void:
	if not is_authority():
		return
	
	_timer = Timer.new()
	_timer.timeout.connect(_tick)
	add_child(_timer)
	
	_update_timer()
	
	_timer.start()

func is_authority() -> bool:
	if server_authority and (not SimusNetConnection.is_server()):
		return false
	return is_multiplayer_authority()

func _update_timer() -> void:
	if not is_authority():
		return
	if not _timer:
		return
	if not is_instance_valid(_timer):
		return
	
	_timer.wait_time = 1.0 / tickrate

func _tick() -> void:
	if not is_authority():
		return
	tick.emit()
