extends Node3D

@export var objects: int = 1000
@export var _scene: PackedScene

func _ready() -> void:
	for i in objects:
		var node: Node = _scene.instantiate()
		node.name = str(i)
		add_child(node)
