@tool
extends EditorInspectorPlugin

const API_DIR  := "res://addons/gopilot_utils/api_providers"

#const CHAT_TESTER := preload("res://addons/gopilot_utils/scenes/chat_test.tscn")

var plugin:EditorPlugin



func _can_handle(object: Object) -> bool:
	return object is ChatRequester


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if object is not ChatRequester:
		return false
	if object.api_script and name in object.api_script._get_hidden_properties() and name != "api":
		return true
	if name == "provider":
		var api_dropdown := OptionButton.new()
		api_dropdown.item_selected.connect(func(index:int):
			object.provider = api_dropdown.get_item_text(index)
			var api_scripts:PackedStringArray = []
			for file in DirAccess.get_files_at(API_DIR):
				if file.ends_with(".gd"):
					api_scripts.append(file)
			object.set_api_script(load(API_DIR + "/" + api_scripts[index]))
			object.notify_property_list_changed()
			)
		var api_providers:PackedStringArray = []
		var current_selection:int = -1
		var i:int = 0
		for file in DirAccess.get_files_at(API_DIR):
			if file.ends_with(".gd"):
				api_providers.append(file.trim_suffix(".gd"))
				api_dropdown.add_item(file.trim_suffix(".gd"))
				if file.begins_with(object.provider):
					current_selection = i
				i += 1
		if current_selection >= 0:
			api_dropdown.select(current_selection)
		add_custom_control(api_dropdown)
		return true
	return false


func set_plugin(_plugin:EditorPlugin):
	plugin = _plugin
