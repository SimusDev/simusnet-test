@tool
extends Node3D
class_name CT_ModelOptimizer3D

@export var model_root: Node3D

@export_tool_button("Optimize and Duplicate") var _optimize_button: Callable = optimize

func optimize() -> void:
	if !model_root:
		return
	
	await SD_Nodes.async_clear_all_children(self)
	_parse(self, model_root)

static func _parse(root: Node3D, from: Node) -> void:
	var id: int = 0
	for node in from.get_children():
		_parse(root, node)
		
		if node is VisualInstance3D:
			id += 1
			var duplicated: Node = node.duplicate()
			duplicated.name = str(id)
			root.add_child(duplicated, true)
			duplicated.global_transform = node.global_transform
			duplicated.owner = node.get_tree().edited_scene_root
