@tool
extends SD_NodeLocalizator
class_name SD_NodeLocalizatorProperty

@export var property: StringName = "text"

func _parse_node(node: Node) -> void:
	if property in node:
		node.set(property, get_localized_text())
	else:
		SD_Console.i().write_from_object(self, "node doesn't have property: %s" % property, SD_ConsoleCategories.ERROR)
