@tool
extends Control

const SETTINGS_DIR:String = "res://addons/gopilot_assist/settings.json"

var COMMON := preload("res://addons/gopilot_utils/scripts/common.gd").new()

var client:HTTPClient = HTTPClient.new()

var conversation:Array[Dictionary] = []
var buddy:GopilotBuddy
var plugin:EditorPlugin
var generating:bool = false
enum MODELS {CHAT, TOOL, CODE}

@onready var settings_window:ConfirmationDialog = %SettingsWindow

@export var all_requesters:Array[ChatRequester]
@export var connected_texture:Texture2D
@export var connecting_texture:Texture2D
@export var sparkle_icon:Texture2D
@export var play:Texture2D
@export var stop:Texture2D
@export var script_icon:Texture2D
@export_multiline var example_prompts:Array[String]
@export var text_field:TextEdit
@export var chat_icon:Texture2D
@export var chat_model:ChatRequester
@export var code_model:ChatRequester
@export var flash_model:ChatRequester
@export var architect_model:ChatRequester

const BUDDY_DIR := "res://addons/gopilot_assist/buddies/"

func _ready() -> void:
	# Gets the settings from the window
	var settings:Dictionary = settings_window.get_settings()
	buddy = load(BUDDY_DIR + settings["current_buddy"] + "/" + settings["current_buddy"] + ".tres")
	var buddy_scene:PackedScene = buddy.buddy
	%ChatConversation.set_buddy(buddy_scene.instantiate())
	%ChatConversation.set_user(settings["user_name"])
	_on_settings_saved()
	%SendMessageBtn.disabled = true
	%StatusIcon.texture = connecting_texture
	var notify_disconnect:Callable = func():
		%PromptField.set_interactable(false)
		%StatusIcon.texture = connecting_texture
	var notify_connected:Callable = func():
		%PromptField.set_interactable(true)
		%StatusIcon.texture = connected_texture
	for i:ChatRequester in all_requesters:
		i.connected_to_host.connect(notify_connected)
		i.disconnected_from_host.connect(notify_disconnect)
	
	set_system_prompt(_prase_system_prompt(buddy.system_prompt))
	chat_model.message_start.connect(func():
		%PromptField.set_status("Writing")
		)
	chat_model.message_end.connect(func(full_message:String):
		generating = false
		%PromptField.set_generating(false)
		_on_user_input_text_changed("")
		)
	%NewChatBtn.pressed.connect(func():
		%PromptField.clear_suggestions()
		conversation = []
		for i in chats:
			i.stop_generation(true, false)
		%ChatConversation.clear_conversation()
		%PromptField.grab_text_focus()
		_on_settings_saved()
		setup_tools()
		)
	_read_buddies()
	_setup_chat()
	_on_user_input_text_changed("")
	_setup_buddies()
	setup_tools()
	%SendMessageBtn.disabled = true
	
	%ChatConversation.set_chat(chat_model)


func set_system_prompt(system_prompt:String) -> void:
	if conversation.size() == 0:
		conversation = [{"role":"system", "content":system_prompt}]
		return
	if conversation[0]["role"] != "system":
		conversation.insert(0, {"role":"system", "content":system_prompt})
		return
	conversation[0]["content"] = system_prompt


# Updates system prompt with buddy prompt infused with buddy info
func update_buddy_system_prompt():
	var settings:Dictionary = settings_window.get_settings()
	var buddy_name:String = settings["current_buddy"]
	var buddy:GopilotBuddy = load(BUDDY_DIR + buddy_name + "/" + buddy_name + ".tres")
	set_system_prompt(_prase_system_prompt(buddy.system_prompt))


const TOOLS_DIR := "res://addons/gopilot_assist/tools"

func _handle_dropdown_pressed(index:int, retrieval_tools:Array[GopilotTool]):
	var tool := retrieval_tools[index]
	if tool.trigger_prompts.size() == 0:
		text_field.insert_text_at_caret(" [NO TRIGGER PROMPT FOR '" + tool.tool_name + "'] ")
	else:
		text_field.insert_text_at_caret(" " + tool.trigger_prompts[0] + " ")


var next_tool:GopilotTool


func _on_conversation_dropdown_selected(index:int):
	if index == 0:
		next_tool = null
		return
	else:
		next_tool = %ConversationTypeDropdown.get_item_metadata(index)


func setup_tools():
	# Removes all existing tools
	for child in %Tools.get_children():
		%Tools.remove_child(child)
		child.queue_free()
	
	# Removes all retrieval tools from dropdown
	%ToolsDropdown.get_popup().clear()
	
	var conv_dropdown:OptionButton = %ConversationTypeDropdown
	var current_conv_index:int = conv_dropdown.selected
	conv_dropdown.clear()
	conv_dropdown.add_icon_item(chat_icon, "Chat")
	conv_dropdown.set_item_metadata(-1, null)
	conv_dropdown.set_item_tooltip(-1, "Default chat mode. Works with GopilotBuddies")
	
	var retrieval_tools:Array[GopilotTool] = []
	
	# Finding all tools in tools directory
	var dirs := DirAccess.get_directories_at(TOOLS_DIR)
	var dropdown_popup:PopupMenu = %ToolsDropdown.get_popup()
	for dir in dirs:
		var tool_dir := TOOLS_DIR + "/" + dir
		if "tool.tscn" not in DirAccess.get_files_at(tool_dir):
			push_warning("Gopilot Tool Initialisation: Could not find 'tool.tscn' in '" + tool_dir + "'. Continuing")
			continue
		var tool_scene:PackedScene = load(tool_dir + "/tool.tscn")
		var tool:Node = tool_scene.instantiate()
		
		if tool is GopilotTool:
			if !tool.is_active:
				tool.queue_free()
				continue
			
			%Tools.add_child(tool)
			
			if tool.is_retrieval_tool:
				if tool.trigger_prompts.is_empty():
					continue
				retrieval_tools.append(tool)
				dropdown_popup.add_icon_item(tool.icon, tool.tool_name.capitalize())
				dropdown_popup.set_item_tooltip(-1, tool.tool_description)
			else:
				conv_dropdown.add_icon_item(tool.icon, tool.tool_name.capitalize())
				conv_dropdown.set_item_metadata(-1, tool)
				conv_dropdown.set_item_tooltip(-1, tool.tool_description)
		else:
			printerr("Gopilot Tool Initialisation: Tool '" + tool_dir + "' is not of type GopilotTool and will not be added. Continuing")
	
	if !conv_dropdown.item_selected.is_connected(_on_conversation_dropdown_selected):
		conv_dropdown.item_selected.connect(_on_conversation_dropdown_selected)
	
	if dropdown_popup.index_pressed.is_connected(_handle_dropdown_pressed):
		dropdown_popup.index_pressed.disconnect(_handle_dropdown_pressed)
	dropdown_popup.index_pressed.connect(_handle_dropdown_pressed.bind(retrieval_tools))
	
	conv_dropdown.select(current_conv_index)
	conv_dropdown.item_selected.emit(current_conv_index)
	
	text_field.syntax_highlighter.keyword_colors = {}
	
	for tool:GopilotTool in %Tools.get_children():
		tool.chat_model = chat_model
		tool.flash_model = flash_model
		tool.code_model = code_model
		tool.architect_model = architect_model
		tool.embed_model = %EmbedRequester
		tool._chat_window_root = self
		tool._conversation = %ChatConversation
		tool.prompt_field = %PromptField
		if tool.is_active:
			for trigger in tool.trigger_prompts:
				text_field.syntax_highlighter.keyword_colors[trigger] = tool.trigger_color


func add_custom_control(control:Control) -> void:
	%ChatConversation.add_custom_control(control)


func add_tool_hints():
	for child in %ExampleCon.get_children():
		child.queue_free()
	for tool:GopilotTool in %Tools.get_children():
		if !tool.is_active or tool.trigger_prompts.size() == 0:
			continue
		var btn := Button.new()
		var button_text:String = ""
		for trigger in tool.trigger_prompts:
			button_text += trigger + "\n"
		btn.text = button_text
		btn.tooltip_text = tool.tool_description
		btn.add_theme_color_override("font_color", tool.trigger_color)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		%ExampleCon.add_child(btn)
		btn.pressed.connect(text_field.insert_text_at_caret.bind(tool.trigger_prompts[0]))


func set_buddy(buddy:GopilotBuddy):
	var scene:PackedScene = buddy.buddy
	%ChatConversation.set_buddy(scene.instantiate())
	var system_prompt:String = _prase_system_prompt(buddy.system_prompt)
	print("Setting system prompt to: " + system_prompt)
	set_system_prompt(system_prompt)
	chat_model.options = buddy.custom_options


func _setup_buddies():
	var popup:PopupMenu = %BuddyBtn.get_popup()
	popup.clear()
	var dirs := DirAccess.get_directories_at(BUDDY_DIR)
	for dir in dirs:
		popup.add_item(dir)
	popup.index_pressed.connect(func(index:int):
		if index == dirs.size():
			%BuddyStudioWindow.popup()
			return
		print("getting file: " + BUDDY_DIR + dirs[index] + "/" + dirs[index] + ".tres")
		if !FileAccess.file_exists(BUDDY_DIR + dirs[index] + "/" + dirs[index] + ".tres"):
			print("Buddy file does not exist!")
			return
		buddy = load(BUDDY_DIR + dirs[index] + "/" + dirs[index] + ".tres")
		set_buddy(buddy)
		settings_window.get_settings()["current_buddy"] = dirs[index]
		settings_window._on_confirmed()
		)
	popup.add_item("Create Buddy")


func _setup_chat():
	var highlighter := preload("res://addons/gopilot_assist/scripts/chat_syntax_highlighter.gd").new()
	%PromptField.set_syntax_highlighter(highlighter)


func _read_buddies():
	for child in %Buddies.get_children():
		child.queue_free()
	var buddies:Array[PackedScene] = []
	var files := DirAccess.get_files_at(BUDDY_DIR)
	for file in files:
		buddies.append(load(BUDDY_DIR + file))
	for scene in buddies:
		var buddy_instance := scene.instantiate()
		var new_entry := %BuddySample.duplicate()
		new_entry.get_node("BuddyCon/BuddyName").text = buddy.name
		new_entry.get_node("BuddyCon/BuddyCon").add_child(buddy_instance)
		new_entry.show()
		%Buddies.add_child(new_entry)


func _setup_embed_requesters():
	var settings:Dictionary = settings_window.get_settings()
	%EmbedRequester.host = settings["host"]
	%EmbedRequester.port = settings["port"]


func set_plugin(_plugin:EditorPlugin):
	plugin = _plugin
	settings_window.confirmed.connect(plugin.reload_settings)


func send_message(msg:String, user_bubble:bool = true, assistant_bubble:bool = true, add_message:bool = true):
	#%ExampleScroller.hide()
	var citations:Array[Control] = []
	
	msg = msg.replace("/nodes", "selected nodes").replace("/code", "selected code").replace("/script", "[color=skyblue]script[/color]")
	if user_bubble:
		%ChatConversation.create_user_bubble(msg, citations)
	if assistant_bubble:
		%ChatConversation.create_assistant_bubble("")
	if add_message:
		var prompt_dict:Dictionary = COMMON.parse_prompt(msg)
		var prompt:String = prompt_dict["prompt"]
		conversation.append({"role": "user", "content": prompt})
		printerr("Weird old code! Please report!")
	chat_model.generate_with_conversation(conversation)
	%UserInput.text = ""
	await chat_model.message_end
	%ChatConversation.play_godot_animation("idle")


func get_editor() -> CodeEdit:
	return EditorInterface.get_script_editor().get_current_editor().get_base_editor()


func get_models() -> PackedStringArray:
	var models:PackedStringArray = await chat_model.get_models()
	return models

enum STATES {IDLE, GENERATING, DONE}
var code_before_completion:String = ""
var state:STATES = STATES.IDLE
var generated_code:String = ""


func _listener_input(event:InputEvent):
	if event is InputEventKey:
		var keycode:String = event.as_text_keycode()
		if keycode in last_shortcut_pressed or not "+" in keycode:
			last_shortcut_pressed = keycode
			return
		last_shortcut_pressed = keycode
		%ShortcutListener.text = keycode


var listening_for_shortcut:bool = false


const suggestion_offset:Vector2 = Vector2(-8.0, -4.0)
const INITIAL_SIZE:Vector2i = Vector2i(540, 40)

var last_shortcut_pressed:String = ""

var newline_amount:int = 0


@onready var chats:Array[ChatRequester] = [code_model, flash_model, chat_model]


func _on_user_input_text_changed(prompt:String) -> void:
	if prompt == "":
		%SendMessageBtn.disabled = true
	else:
		%SendMessageBtn.disabled = false


func add_task(title:String, icon:Texture2D = preload("res://addons/gopilot_utils/textures/Tools.png")):
	%ChatConversation.add_action(title, icon)


func update_task(title:String):
	%ChatConversation.update_action_title(title)


func _on_settings_saved():
	var settings:Dictionary = settings_window.get_settings()
	%ChatConversation.set_user(settings["user_name"])
	%ChatConversation.user_role_name = settings["user_name"]
	%ChatConversation.use_markdown_formatting = settings["use_markdown_formatting"]
	
	chat_model.apply_config(settings["chat_model"])
	code_model.apply_config(settings["code_model"])
	architect_model.apply_config(settings["architect_model"])
	flash_model.apply_config(settings["flash_model"])
	%ChatConversation.buddy_visible = settings["show_buddy"]
	%ChatConversation.welcome_message_visible = settings["show_welcome_message"]
	buddy = load(BUDDY_DIR + settings["current_buddy"] + "/" + settings["current_buddy"] + ".tres")
	set_system_prompt(_prase_system_prompt(buddy.system_prompt))


const RECOMMENDATIONS_PRT := """Based on our conversation so far, what might I ask you next?
Respond in plaintext bulletpoint list with question and summary like this:
- How can I do that think you just described? (Question)
- Write the code for that (Code writing)
- What nodes should I use for that? (Node question)
...

4 points max
ONLY RESPOND WITH BULLETPOINT LIST"""


var recommendation_delta:String = ""

var currently_running_tool:GopilotTool

func _on_prompt_submitted(prompt: String) -> void:
	update_buddy_system_prompt()
	%PromptField.clear_suggestions()
	var recommend:bool = %SettingsWindow.get_settings()["generate_recommendations"]
	var use_retrieval_tools:bool = %ToolsCheck.button_pressed
	var sent_message:bool = false
	%ChatConversation.create_user_bubble(prompt)
	#chat_model.send_message(prompt)
	conversation.append({"role": "user", "content": prompt})
	if use_retrieval_tools:
		var retrieval_tools:Array[GopilotTool] = []
		#var agentic_tools:Array[GopilotTool] = []
		for tool:GopilotTool in %Tools.get_children():
			var added:bool = false
			if !tool.is_active:
				continue
			for trigger in tool.trigger_prompts:
				if trigger in prompt:
					if tool.is_retrieval_tool:
						retrieval_tools.append(tool)
						added = true
					#else:
						#agentic_tools.append(tool)
						#added = true
					break
			if tool._is_elegible(conversation) and !added:
				if tool.is_retrieval_tool:
					retrieval_tools.append(tool)
				#else:
					#agentic_tools.append(tool)
				break
		
		%PromptField.set_status("Tooling")
		for tool in retrieval_tools:
			currently_running_tool = tool
			await tool._run_tool(conversation)
		#for tool in agentic_tools:
			#currently_running_tool = tool
			#await tool._run_tool(conversation)
	if next_tool != null:
		%PromptField.set_status("Tooling")
		currently_running_tool = next_tool
		await next_tool._run_tool(conversation)
	
	%PromptField.set_status("Loading")
	
	chat_model.new_word.connect(%ChatConversation.add_to_last_bubble)
	send_message(prompt, false, true, false)
	generating = true
	await chat_model.message_start
	%PromptField.set_status("Writing")
	%ChatConversation.play_godot_animation("talk")
	var result:String = await chat_model.message_end
	conversation.append({"role": "assistant", "content": result})
	generating = false
	%PromptField.set_generating(false)
	_on_user_input_text_changed("")
	chat_model.new_word.disconnect(%ChatConversation.add_to_last_bubble)
	if !recommend:
		return

	%PromptField.set_generating(true)
	%PromptField.set_status("Prompting")
	var prefix := "- "
	var conv_with_prompt = conversation.duplicate()
	conv_with_prompt.append({"role":"user", "content":RECOMMENDATIONS_PRT})
	flash_model.generate_with_conversation(conv_with_prompt)
	var message:String = await flash_model.message_end
	var recommendations:PackedStringArray = message.split("\n")
	for recommendation in recommendations:
		var summary:String = recommendation.split("(")[-1].trim_suffix(")")
		recommendation = recommendation.trim_prefix("- ").split(" (")[0]
		%PromptField.add_suggestion(summary, recommendation)
	flash_model.options.erase("stop")
	%PromptField.set_generating(false)


func _on_stop_pressed() -> void:
	if currently_running_tool:
		currently_running_tool._cancel_tool()
	generating = false
	%PromptField.set_generating(false)
	%PromptField.grab_text_focus()
	for i in all_requesters:		i.reconnect(true, true)
	%ChatConversation.play_godot_animation("idle")


var last_focussed_item:Control


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if !event.is_pressed():
			return
		var keycode:String = event.as_text_keycode()
		if keycode == settings_window.get_settings()["chat_shortcut"]:
			accept_event()
			if %PromptField.has_text_focus() and last_focussed_item:
				last_focussed_item.grab_focus()
				return
			else:
				last_focussed_item = get_viewport().gui_get_focus_owner()
				show()
				%PromptField.grab_text_focus()


func _prase_system_prompt(system:String) -> String:
	var settings:Dictionary =  settings_window.get_settings()
	system = system.replace("{{custom_instructions}}", settings["custom_instructions"])
	system = system.replace("{{name}}", settings["user_name"]).replace("{{pronouns}}", settings["pronouns"])
	
	var file_tree:String = COMMON.directory_tree_to_string_with_rules("res://", 4, "  ", "", ["gd", "tscn", "png", "jpg", "svg", "txt", "json", "yaml", "md"], ["res://addons"])
	system = system.replace("{{file_tree}}", file_tree)
	var root_node = EditorInterface.get_edited_scene_root()
	var scene_tree:String = COMMON.get_node_as_string(root_node, 5, "  ", "")
	system = system.replace("{{scene_tree}}", scene_tree)
	return system
