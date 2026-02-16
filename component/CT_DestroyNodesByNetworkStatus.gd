extends CT_ByNetworkStatusBase
class_name CT_DestroyNodesByNetworkStatus

@export var _nodes: Array[Node]

func _status_success() -> void:
	for i in _nodes:
		if is_instance_valid(i):
			i.queue_free()
