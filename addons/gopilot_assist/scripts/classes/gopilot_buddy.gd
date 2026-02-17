extends Resource
class_name GopilotBuddy

## Name of the buddy
@export var name:String = "code writer"

## The icon which is displayed in the tab view when talking to the assistant
@export var icon:Texture2D = preload("res://addons/gopilot_utils/textures/sparkle.svg")

## The Godot buddy you want to appear above the chat flow. Leave empty to not have a buddy
## Scene should have an AnimationPlayer with name "Anim" as a child, to have some aniations.
## Supported animations include: "idle" and "talk"
@export var buddy:PackedScene

## Role and character of the model. Example:
## [codeblock]
## You are an integrated AI assistant in the Godot 4 Game Engine.
## You have access to several tools to help me write better GDScript code.
## [/codeblock]
@export_multiline var system_prompt:String = ""

## When true, applies the [member custom_temperature] to the model
@export var use_custom_temperature:bool = false

## The temperature, or creativity of the model. (Llama models work best at around 0.7)
## Only affects the model when [member use_custom_temperature] is true
@export_range(0.0, 10.0) var custom_temperature:float = 0.7

## Here you can set some advanced options for generations, like Top_K and the context length
## Only use this, if you know what you are doing!
## When using a temperature key in here, it will override [member custom_temperature]
@export var custom_options:Dictionary[String, Variant] = {}
