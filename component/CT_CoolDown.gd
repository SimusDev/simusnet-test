class_name CT_CoolDown extends Node

signal started()
signal finished()


@export var time:float = 1.0
var time_left:float = 0.0 :
	set(val):
		val = clampf(val, 0.0, time)
		time_left = val

var _enabled:bool = false

func _init() -> void:
	time_left = time

func _ready() -> void:
	pass

func in_cooldown() -> bool:
	return time_left < time

func start(from:float = 0.0) -> void:
	_enabled = true
	time_left = from
	
	started.emit()

func seek(to:float) -> void:
	time_left = to

func stop() -> void:
	_enabled = false
	
	finished.emit()

func _physics_process(delta: float) -> void:
	if not _enabled:
		return
	
	if time_left < time:
		time_left += delta
		return
