extends CT_ByNetworkStatusBase
class_name CT_CreatePrefabsFileByNetworkStatus

@export var root: Node
@export_file("*.tscn", "*.scn") var _prefabs: Array[String]
@export var destroy_self_after_fail: bool = true

func _status_success() -> void:
	for file: String in _prefabs:
		var scene: PackedScene = load(file)
		root.add_child(scene.instantiate(), true)

func _status_fail() -> void:
	if destroy_self_after_fail:
		queue_free()
