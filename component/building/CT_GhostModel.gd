#@tool
@static_unload
extends Node3D
class_name CT_GhostModel

static func _parse(model: CT_GhostModel, from: Node) -> void:
	for node in from.get_children():
		_parse(model, node)
		
		if node is VisualInstance3D:
			var duplicated: Node = node.duplicate()
			model.add_child(duplicated)
			duplicated.owner = model

static func create(from: Node) -> CT_GhostModel:
	var model: CT_GhostModel = CT_GhostModel.new()
	_parse(model, from)
	return model
