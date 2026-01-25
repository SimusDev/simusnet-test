extends Label

var key: String = ""
var data: Dictionary = {}

func _ready() -> void:
	update()
	SimusNetProfiler.get_instance().on_rpc_profiler_change.connect(_on_key_update)
	

func _on_key_update(_key: String) -> void:
	if _key == key:
		update()

func update() -> void:
	text = "%s: " % [key]
