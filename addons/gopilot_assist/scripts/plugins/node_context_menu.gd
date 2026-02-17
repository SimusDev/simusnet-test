extends EditorContextMenuPlugin


var COMMON := preload("res://addons/gopilot_utils/scripts/common.gd").new()

func _popup_menu(paths: PackedStringArray) -> void:
	#print("paths: ", paths)
	if paths.size() != 1:
		return
	if EditorInterface.get_edited_scene_root().get_node(paths[0]) is not Control:
		return
	add_context_menu_item("some example item", print, preload("res://addons/gopilot_utils/textures/sparkle.svg"))


func item_selected(nodes:Array[Node]):
	
	pass
