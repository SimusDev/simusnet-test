extends EditorContextMenuPlugin

const SPARKLE := preload("res://addons/gopilot_utils/textures/sparkle.svg")

var complete_code_scortcut:Shortcut = preload("res://addons/gopilot_assist/shortcuts/complete_code.tres")

var overlay:Control


# 
func set_overlay(_overlay:Control):
	overlay = _overlay


# Add context menu items for code completion and translation
func _popup_menu(paths: PackedStringArray) -> void:
	if paths[0].ends_with(".csv"):
		add_context_menu_item("Translate table", open_translation_panel, SPARKLE)


# Open the translation panel when a CSV file is selected
func open_translation_panel(file:PackedStringArray):
	overlay.open_translation_panel(file[0])
