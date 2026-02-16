extends CT_ByNetworkStatusBase
class_name CT_CreatePrefabsByNetworkStatus

@export var root: Node
@export var _prefabs: Array[PackedScene]
@export var destroy_self_after_fail: bool = true

func _status_success() -> void:
	for scene: PackedScene in _prefabs:
		if scene:
			root.add_child(scene.instantiate(), true)

func _status_fail() -> void:
	if destroy_self_after_fail:
		queue_free()
