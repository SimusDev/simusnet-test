extends Control

@export var _rpc_info_scene: PackedScene
@export var _container: Control

func _ready() -> void:
	var profiler: Dictionary[String, Dictionary] = SimusNetProfiler.get_instance()._rpcs_profiler
	for key in profiler:
		var ui: Control = _rpc_info_scene.instantiate()
		ui.key = key
		ui.data = profiler[key]
		_container.add_child(ui)
	
	SimusNetProfiler.get_instance().on_rpc_profiler_add.connect(_on_rpc_profiler_add)

func _on_rpc_profiler_add(key: String, data: Dictionary) -> void:
	var ui: Control = _rpc_info_scene.instantiate()
	ui.key = key
	ui.data = data
	_container.add_child(ui)
