@tool
extends Control

enum Role {SYSTEM, ASSISTANT, USER, TOOL}

var messages:Array[Control]

signal remove_message_requested(message_index:int)
signal edit_message_requested(message_index:int, new_text:String)

const CONVERSATION_CONTEXT_OPTIONS:Dictionary[String, Callable] = {
	#"Remove Message":
}

var COMMON := preload("res://addons/gopilot_utils/scripts/common.gd").new()


@export var in_editor:bool = false:
	set(new):
		in_editor = new
		if !is_node_ready():
			return
		%ChatEntrySample.in_editor = new

@export var use_markdown_formatting:bool = true

@export var buddy_visible:bool = true:
	set(new):
		buddy_visible = new
		if is_node_ready():
			%BuddyCon.visible = new
		else:
			ready.connect(func():
				var buddy_con:CenterContainer = get_node("%BuddyCon")
				buddy_con.set_visible.bind(new))

#
@export var welcome_message_visible:bool = true:
	set(new):
		welcome_message_visible = new
		if is_node_ready():
			%WelcomeMessage.visible = new
		else:
			ready.connect(%WelcomeMessage.set_visible.bind(new))

@export var warning_visible:bool = true:
	set(new):
		warning_visible = new
		if is_node_ready():
			%Warning.visible = new
		else:
			ready.connect(%Warning.set_visible.bind(new))

@export_group("User", "user_")
## Role name displayed in chat window
@export var user_role_name:String = "User"
## Allows user to regenerate message content. Makes most sense in "Assistant" category, since user uses [member user_can_edit] instead
@export var user_can_retry:bool = false
## Allows user to edit their message. Useful if they want to iterate the output of the LLM
@export var user_can_edit:bool = false
## Allows to copy content via button
@export var user_can_copy:bool = true
## Allows removing all chat entries above this one
@export var user_can_remove:bool = false

@export_group("Assistant", "assistant_")
## Role name displayed in chat window
@export var assistant_role_name:String = "Assistant"
## Allows user to regenerate message content
@export var assistant_can_retry:bool = false
## Allows user to edit the assistants message. Can be used for ICL ([b]I[/b]n [b]C[/b]ontext [b]L[/b]earning) and better output alignment
@export var assistant_can_edit:bool = false
## Allows to copy content via button
@export var assistant_can_copy:bool = true
## Allows removing all chat entries above this one. Makes most sense in "User" category
@export var assistant_can_remove:bool = false

@export_group("Node pointers")
@export var conversation:VBoxContainer

func _process(delta:float):
	%ScrollCon.scroll_vertical = %ContentCon.size.y


var locked_to_floor:bool = true


func scroll_container_input(event:InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			locked_to_floor = false
			set_process(false)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if %ContentCon.size.y - %ScrollCon.size.y == %ScrollCon.scroll_vertical or\
			%ContentCon.size.y == %ScrollCon.size.y:
				locked_to_floor = true
				set_process(true)


func play_godot_animation(animation:String):
	if %BuddyCon.get_child_count() != 0:
		%BuddyCon.get_child(0).get_node("Anim").play(animation)


func _ready() -> void:
	play_godot_animation("idle")
	%ScrollCon.gui_input.connect(scroll_container_input)


func clear_conversation():
	for child in conversation.get_children():
		child.queue_free()
	messages.clear()




func add_custom_control(control:Control) -> void:
	conversation.add_child(control)


func update_conversation(con:Array[Dictionary]) -> void:
	for msg in con:
		create_custom_bubble(msg["role"], msg["content"])

var text_so_far:String = ""

func create_custom_bubble(role:String = "", content:String = "", citations:Array[Control] = [], can_retry:bool = false, can_edit := false, can_copy := true, can_remove := false):
	text_so_far = ""
	var new_chat_bubble := %ChatEntrySample.duplicate()
	match role:
		"Assistant", "assistant": new_chat_bubble.set_role(role, true, false, false)
		"User", "user": new_chat_bubble.set_role(role, true, true, false)
		_: new_chat_bubble.set_role(role)
	new_chat_bubble.set_message(content)
	for cite in citations:
		new_chat_bubble.add_citation(cite)
	messages.append(new_chat_bubble)
	conversation.add_child(new_chat_bubble, true)
	new_chat_bubble.request_edit.connect(_on_message_edit)
	new_chat_bubble.request_remove.connect(_on_message_remove)
	new_chat_bubble.show()
	last_bubble = conversation.get_child(-1)


var last_action:Control

func add_action(action_name:String, icon:Texture2D):
	var action := %ActionSample.duplicate()
	action.get_node("BtnCon/Button").text = action_name
	action.get_node("BtnCon/Button").icon = icon
	action.show()
	conversation.add_child(action)
	last_action = action


func add_sub_action(sub_action_text:String):
	if !last_action:
		push_error("Gopilot: No last action found. Only call 'add_sub_action' when you added an action beforehand using 'add_action'")
		return
	var sub_action:RichTextLabel = %SubActionSample.duplicate()
	sub_action.text = sub_action_text
	sub_action.show()
	last_action.get_node("BtnCon/SubTasksCon").add_child(sub_action)


## Can only be called when there is no chat block after the action block
func update_action_title(action_name:String):
	if !last_action:
		push_error("Gopilot: No last action found. Only call 'update_action_title' when you added an action beforehand using 'add_action'")
		return
	last_action.get_node("BtnCon/Button").text = action_name


func append_text_to_last_sub_action(new_text:String) -> void:
	if !last_action:
		push_error("Gopilot: No last action found. Only call 'append_text_to_last_sub_action' when you added an action beforehand using 'add_action'")
		return

	var sub_tasks_con:Container = last_action.get_node("BtnCon/SubTasksCon")
	if sub_tasks_con.get_child_count() == 0:
		push_error("Gopilot: No sub-actions found. Only call 'append_text_to_last_sub_action' when there is at least one sub-action.")
		return

	var last_sub_action:RichTextLabel = sub_tasks_con.get_child(-1)
	last_sub_action.text += new_text


func _on_message_edit(new_text:String, message:Control):
	var parsed_data:Dictionary[String, Variant] = COMMON.parse_prompt(new_text)
	message.clear_citations()
	var prompt:String = parsed_data["prompt"]
	var citations:Array[Dictionary] = parsed_data["citations"]
	for cite in citations:
		message.add_citation(cite)
	edit_message_requested.emit(messages.find(message), new_text)
	if chat:
		var message_index:int = -(messages.size() - messages.find(message))
		chat.conversation[message_index]["content"] = prompt


func _on_message_remove(message:Control):
	remove_message_requested.emit(messages.find(message))
	var index := message.get_index()
	var amount_to_remove:int = conversation.get_child_count() - message.get_index()
	for i in amount_to_remove:
		conversation.get_child(-i - 1).queue_free()
		messages.pop_back()
	if chat:
		for i in amount_to_remove:
			chat.get_conversation().pop_back()


func create_user_bubble(prompt:String, citations:Array[Control] = []):
	create_custom_bubble(user_role_name, prompt, citations, user_can_retry, user_can_edit, user_can_copy, user_can_remove)


func add_citation_to_last_bubble(citation:Control) -> void:
	if conversation.get_child_count() == 0:
		print("could not add")
		return
	last_bubble.add_citation(citation)


func create_assistant_bubble(prompt:String = "", citations:Array[Control] = []):
	create_custom_bubble(assistant_role_name, prompt, citations, assistant_can_retry, assistant_can_edit, assistant_can_copy, assistant_can_remove)


var last_bubble:Control

func add_to_last_bubble(new_word:String) -> void:
	if conversation.get_child_count() == 0:
		return
	text_so_far += new_word
	last_bubble.set_message(text_so_far)


func pop_last_bubble():
	if conversation.get_child_count() > 0:
		conversation.get_child(-1).queue_free()


func set_user(user:String, format:String = "[b]Hello {.user}[/b]\nWhat would you like to do?"):
	%WelcomeMessage.text = format.replace("{.user}", user)


func set_buddy(buddy:Control):
	if %BuddyCon.get_child_count() != 0:
		for child in %BuddyCon.get_children():
			child.queue_free()
	%BuddyCon.add_child(buddy)
	buddy.get_node("Anim").play("idle")


var chat:ChatRequester

func set_chat(_chat:ChatRequester):
	chat = _chat
