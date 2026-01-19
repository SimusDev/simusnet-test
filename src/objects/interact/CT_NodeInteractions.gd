extends Node
class_name CT_NodeInteractions

@export var target: Node
@export var list: Array[R_InteractAction] = []

func _ready() -> void:
	for i in list:
		i.append_to(target)
