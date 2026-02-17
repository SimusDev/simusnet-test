@tool
extends EditorPlugin

const GO_PILOT_CHAT_WINDOW:PackedScene = preload("res://addons/gopilot_assist/scenes/gopilot_chat_window.tscn")
const CHAT_REQUESTER_SCRIPT := preload("res://addons/gopilot_utils/classes/chat_requester.gd")
const CHAT_REQUESTER_ICON := preload("res://addons/gopilot_utils/textures/chat_requester_icon.svg")
const AGENT_HANDLER_SCRIPT := preload("res://addons/gopilot_utils/classes/agent_handler.gd")
const AGENT_HANDLER_ICON := preload("res://addons/gopilot_utils/textures/agent_handler_icon.svg")
const EMBED_REQUESTER_SCRIPT := preload("res://addons/gopilot_utils/classes/embed_requester.gd")
const EMBED_REQUESTER_ICON := preload("res://addons/gopilot_utils/textures/embed_requester_icon.svg")

var chat_window := GO_PILOT_CHAT_WINDOW.instantiate()
@onready var code_helper:ChatRequester = chat_window.code_model
var script_editor:CodeEdit

var node_content_menu_plugin := preload("res://addons/gopilot_assist/scripts/plugins/node_context_menu.gd").new()

var context_menu_plugin := preload("res://addons/gopilot_assist/scripts/plugins/context_menu.gd").new()

var gopilot_overlay := preload("res://addons/gopilot_assist/scenes/gopilot_overlay.tscn").instantiate()

var above_script:String = ""
var below_script:String = ""

var generation:String = ""


# This function is called when the plugin enters the tree
func _enter_tree() -> void:
	#if !has_started:
		#await get_tree().create_timer(3.0).timeout
	# Adds overlay to main screen
	gopilot_overlay.set_plugin(self)
	var base_control := EditorInterface.get_base_control()
	base_control.add_child(gopilot_overlay)
	
	# Adds context menu plugin
	context_menu_plugin.set_overlay(gopilot_overlay)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, context_menu_plugin)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE, node_content_menu_plugin)
	
	chat_window.name = "Gopilot"
	
	# Adding to dock first, to ensure chat_window is ready
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, chat_window)
	if chat_window.is_node_ready():
		chat_window.set_plugin(self)
	else:
		await chat_window.ready
		chat_window.set_plugin(self)
	
	# Adding custom types
	add_custom_type("ChatRequester", "Node", CHAT_REQUESTER_SCRIPT, CHAT_REQUESTER_ICON)
	add_custom_type("AgentHandler", "Node", AGENT_HANDLER_SCRIPT, AGENT_HANDLER_ICON)
	add_custom_type("EmbedRequester", "Node", EMBED_REQUESTER_SCRIPT, EMBED_REQUESTER_ICON)


# This function is called when the plugin exits the tree
func _exit_tree() -> void:
	# Removes overlay from the editor
	gopilot_overlay.queue_free()
	
	# Removes context menu plugin
	remove_context_menu_plugin(context_menu_plugin)
	remove_context_menu_plugin(node_content_menu_plugin)
	
	remove_custom_type("ChatRequester")
	remove_custom_type("AgentHandler")
	remove_custom_type("EmbedRequester")
	remove_control_from_docks(chat_window)


func open_gopilot_dock():
	chat_window.show()


var doc_button:Button


func _exit_tree_doc():
	remove_control_from_docks(doc_button)


# This function is called when the "Fetch Documentation" button is pressed
func _on_doc_button_pressed():
	EditorInterface.get_selection()
	#var _class_name = EditorInterface.get_selected_object().get_class()
	#var doc = get_documentation(_class_name)
	#print(doc)



# Written by AI, probably not good
func get_documentation(_class_name: String):
	var doc_url = "https://docs.godotengine.org/en/stable/classes/class_" + _class_name.to_lower() + ".html"
	var doc_request = HTTPRequest.new()
	add_child(doc_request)
	doc_request.request(doc_url)

func _on_doc_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var doc = body.get_string_from_utf8()
		print(doc)
	else:
		print("Failed to fetch documentation. Response code: ", response_code)


func reload_settings():
	gopilot_overlay._read_settings()
	chat_window._on_settings_saved()


func request_action(action:String) -> bool:
	return await gopilot_overlay.request_action(action)
