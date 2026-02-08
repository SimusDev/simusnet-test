extends Control

@export var _container: Control
@export var _scene: PackedScene

func _ready() -> void:
	for bus in SimusDev.audio.get_bus_list():
		var ui: Control = _scene.instantiate()
		ui.bus = bus
		_container.add_child(ui)
