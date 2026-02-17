@tool
extends EditorPlugin

# EmbedRequester inspector plugin
const EMBED_INSPECTOR_PLUGIN := preload("res://addons/gopilot_utils/embed_requester_inspector_plugin.gd")
var embed_inspector_plugin:EditorInspectorPlugin = EMBED_INSPECTOR_PLUGIN.new()


# Leftover from experimental ChatOrchestrator feature. Might be uncommented soon
#const ORCH_INSPECTOR_PLUGIN := preload("res://addons/gopilot_utils/scripts/plugins/chat_orch_plugin.gd")
#var orch_inspector_plugin:EditorInspectorPlugin = ORCH_INSPECTOR_PLUGIN.new()
const CHAT_REQUESTER_PLUGIN := preload("res://addons/gopilot_utils/scripts/plugins/chat_requester_plugin.gd")
var chat_requester_plugin = CHAT_REQUESTER_PLUGIN.new()

var script_editor:CodeEdit



var above_script:String = ""
var below_script:String = ""

var generation:String = ""

func _enter_tree() -> void:
	#add_custom_type("ChatRequester", "Node", preload("res://addons/gopilot_utils/classes/chat_requester.gd"), preload("res://addons/gopilot_utils/textures/chat_requester_icon.svg"))
	#add_custom_type("ToolChatRequester", "ChatRequester", preload("res://addons/gopilot_utils/classes/tool_chat_requester.gd"), preload("res://addons/gopilot_utils/textures/tool_chat_requester_icon.svg"))
	#add_custom_type("EmbedRequester", "Node", preload("res://addons/gopilot_utils/classes/embed_requester.gd"), preload("res://addons/gopilot_utils/textures/embed_requester_icon.svg"))
	add_inspector_plugin(embed_inspector_plugin)
	chat_requester_plugin.set_plugin(self)
	
	add_inspector_plugin(chat_requester_plugin)
	
	#orch_inspector_plugin.set_plugin(self)
	#add_inspector_plugin(orch_inspector_plugin)

func _exit_tree() -> void:
	#remove_custom_type("ChatRequester")
	#remove_custom_type("AgentHandler")
	#remove_custom_type("EmbedRequester")
	remove_inspector_plugin(embed_inspector_plugin)
	remove_inspector_plugin(chat_requester_plugin)
	#remove_inspector_plugin(orch_inspector_plugin)


func request_completion():
	script_editor = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
	EditorInterface.get_script_editor().get_current_editor()
	var script:String = script_editor.text
	#print(script_editor.get_text_for_symbol_lookup())
	#var script_lines:PackedStringArray = script.split("\n")
	#var lines:int = script_editor.get_caret_line()
	#for line in script_lines.size():
		#if line <= lines:
			#above_script += script_lines[line] + "\n"
		#else:
			#below_script += script_lines[line] + "\n"
	#
	#print("Above:\n", above_script, "\n\nBelow:\n", below_script)
