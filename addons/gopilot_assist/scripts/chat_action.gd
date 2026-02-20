@tool
extends PanelContainer

func set_task_text(text:String) -> void:
	$HBoxContainer/Task.text = text


func set_task_icon(icon:Texture2D) -> void:
	$HBoxContainer/MarginContainer/Icon.texture = icon
