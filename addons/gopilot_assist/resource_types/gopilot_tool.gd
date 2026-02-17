@tool
extends Node
class_name GopilotTool
## A resource type to create [b]new Gopilot tools[/b] for the chat[br]
## To add a new tool, follow these steps:[br]
## - Create a new folder under [code]res://addons/gopilot_assist/tools[/code] for your tool. Make sure the name is unique, for example by including your username[br]
## - Create a scene with [GopilotTool] as the base and save it to the new folder with the exact name "tool.tscn"[br]
## - Select the GopilotChat in the scene tree and extend its script. Then override the [method _run_tool] method to customize the tools behaviour[br]
## - Tweak the nodes parameters to align with your vision of the tool[br]
## - If you need more assets for the tool to function (like an icon or another scene), simply place them into your tool folder. As long as none of these new assets have the name "tool.tscn", no proplems will occur[br]
## Added children will be transfered over to the Gopilot chat window. so it's possible to have popup windows for UI interaction[br]
## Use the [member chat_model], [member code_model] and [member tool_model] to generate responses.

## INTERNAL VARIABLE! READ ONLY! Used to add and edit task blocks
var _chat_window_root:Control

## INTERNAL VARIABLE! READ ONLY! Used to add citations to the chat interface
var _conversation:Control

## A ChatRequester with the model the user's selected in the settings
var chat_model:ChatRequester
## A ChatRequester with the model of the user's selected tool model
var flash_model:ChatRequester
## A ChatRequester with the model of the user's selected code completion model
var code_model:ChatRequester
## A ChatRequester with the model of the user's selected architecture model
var architect_model:ChatRequester
## A ChatRequester with the model of the user's selected embedding model
var embed_model:EmbedRequester


var prompt_field:Control

## The name of the tool passed to the LLM when deciding on a tool
@export var tool_name:String = "example_tool"
## Icon for the tool. Should be 16 x 16 pixels large, larger sizes will scale down
@export var icon:Texture2D = preload("res://addons/gopilot_utils/textures/Tools.png")
## When true, can be called along with other retrieval-centered tools, like the built-in /script and /scene
@export var is_retrieval_tool:bool = false
##@deprecated
## Short description of the tool passed to the LLM when deciding on a tool.[br]
## I recommend using examples of what a prompt might look like to trigger your tool. To give you a good idea, this is what the "create_script" description looks like:[br][code]
## Use this tool specifically when the user requests to create a new script. This could be indicated by phrases like "create a script" "write a script" or "generate a script"[/code]
@export_multiline var tool_description:String = "Example tool to test the assistants functionality"
## When these triggers are found in prompts, the tool will be called. This is rule based and doesn't require the LLM to decide on a tool
@export_multiline var trigger_prompts:PackedStringArray
## Color of the trigger prompts in the chat
@export var trigger_color:Color = Color.ORANGE
## To disable the tool in the chat, uncheck this box
@export var is_active:bool = true


#region Overridable functions
## Overridable. This function is run when this tool gets executed. The function will be awaited, so make sure to not get stuck in this function.[br]
## Returns a message for the LLM to know what happened during the tool call and to instruct on what to tell the user[br]
## The [param conversation] has this layout[br]
## [codeblock][
##    {"role":"user", "content":"Hey mister AI!"},
##    {"role":"assistant", "content":"Hello, I am here to help you."},
## ][/codeblock]
func _run_tool(conversation:Array[Dictionary]) -> void:
	add_action_block("Tool '{}' called")
	await get_tree().create_timer(3.0).timeout
	print_rich("[color=skyblue]NO CUSTOM BEHAVIOUR DEFINED FOR TOOL '{0}'[/color]".format([tool_name]))
	for i in 3:
		update_action_block("Waiting for " + str(i + 1) + " seconds ...")
		await get_tree().create_timer(1.0).timeout


## Overridable. This function is run when the user enters a prompt
func _is_elegible(conversation:Array[Dictionary]) -> bool:
	return false


## Overridable. This function is run when the tool call was cancelled by the user[br]
## Please implement this when your tool can take a while to respond, especially when using another LLM to generate a response, like an agent
func _cancel_tool():
	
	pass


#endregion


## Adds a control to the chat VBoxContainer
func add_custom_control(control:Control) -> void:
	
	_conversation.add_custom_control(control)


## Adds a task block to the chat interface, to indicate that the tool is running
func add_action_block(text:String, _icon = icon) -> void:
	_conversation.add_action(text, _icon)


func add_sub_action(subaction_text:String):
	_conversation.add_sub_action(subaction_text)


func append_to_sub_action(text:String):
	_conversation.append_text_to_last_sub_action(text)


## Updates the last added task blocks text
func update_action_block(text:String) -> void:
	_chat_window_root.update_task(text)


## Sets the status indicator at the bottom right of the screen to a given string. Automatically adds three animated dots "..." to the status
func set_status(status:String):
	prompt_field.set_status(status)


## Adds a citation to the chat window. Only visual[br]
## For simplified citations, use [method add_button_citation] method
func add_citation(citation:Control) -> void:
	_conversation.add_citation_to_last_bubble(citation)


const SCRIPT_ICON:Texture2D = preload("res://addons/gopilot_utils/textures/Script.png")

func add_button_citation(text:String, tooltip_text:String = "", icon:Texture2D = SCRIPT_ICON) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip_text
	button.icon = icon
	add_citation(button)
	return button


## Adds a prefix to the last message in the conversation
func add_prefix(conversation:Array[Dictionary], prefix:String) -> void:
	conversation[-1]["content"] = prefix + conversation[-1]["content"]


## Adds a suffix to the last message in the conversation
func add_suffix(conversation:Array[Dictionary], suffix:String) -> void:
	conversation[-1]["content"] = conversation[-1]["content"] + suffix


func add_tag_suffix(conversation:Array[Dictionary], tag_content:String, tag_name:String = "tool_info") -> void:
	var starting_tag:String = "<" + tag_name + ">"
	var ending_tag:String = "</" + tag_name + ">"
	add_suffix(conversation, "\n\n" + starting_tag + tag_content + ending_tag)
