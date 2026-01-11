@icon("res://addons/simusdev/components/fp_controller/source/icon.png")
extends Node3D
class_name W_FPCSource

@export var enabled: bool = true : set = set_enabled

func _ready() -> void:
	_multiplayer_authority_changed()
	_active_status_changed()

func set_enabled(value: bool) -> void:
	if enabled == value:
		return
	
	enabled = value
	_active_status_changed()

func _active_status_changed() -> void:
	pass

func set_multiplayer_authority(id: int, recursive: bool = true) -> void:
	super(id, recursive)
	_multiplayer_authority_changed()

func _multiplayer_authority_changed() -> void:
	pass
