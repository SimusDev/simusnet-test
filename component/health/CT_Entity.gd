extends Node
class_name CT_Entity

@export var object: R_WorldObject

func _ready() -> void:
	pass

func _create_component(instance: Node, script: GDScript, _name: String) -> Node:
	if is_instance_valid(instance):
		return instance
	
	var node: Node = script.new()
	node.name = _name
	add_child(node)
	return node
