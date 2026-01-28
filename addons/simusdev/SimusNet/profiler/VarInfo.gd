extends "InfoBase.gd"

var key: String = ""
var data: Dictionary = {}

func _ready() -> void:
	update()
	SimusNetProfiler.get_instance().on_var_profiler_change.connect(_on_key_update)

func _on_key_update(_key: String) -> void:
	if _key == key:
		update()

func update() -> void:
	key_label.text = key
	up_traffic.text = "Sent %s: %s" % [data.up_calls, String.humanize_size(data.up)]
	down_traffic.text = "Received %s: %s" % [data.down_calls, String.humanize_size(data.down)]
