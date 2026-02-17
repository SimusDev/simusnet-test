@tool
extends Control

signal request_remove(message:Control)
signal request_edit(new_message:String, message:Control)

var COMMON := preload("res://addons/gopilot_utils/scripts/common.gd").new()

@export var in_editor:bool = false:
	set(new):
		in_editor = new
		if !is_node_ready():
			return
		if !new:
			%CodeEdit.syntax_highlighter = null
		else:
			%CodeEdit.syntax_highlighter = GDScriptSyntaxHighlighter.new()

@export var script_icon:Texture2D

@export var text_control:Control

## Sets the message of the interface
## Animates progress bar to end when [param animate] is true
func set_message(msg:String, animate:bool = false):
	if animate:
		await set_progress(100.0)
	%ProgBar.hide()
	text_control.text = msg


func set_role(role:String, can_edit:bool = false, can_remove:bool = false, can_regen:bool = false, can_copy:bool = true):
	%Role.text = role
	%EditBtn.visible = can_edit
	%RemoveBtn.visible = can_remove
	%RegenerateBtn.visible = can_regen
	%CopyBtn.visible = can_copy


var prog_bar_tween:Tween


func _ready() -> void:
	%ProgBar.value = 0.0


## Function to set the progress bar value of the interface
func set_progress(progress:float = 50.0, duration:float = 0.3):
	if prog_bar_tween and prog_bar_tween.is_running():
		prog_bar_tween.kill()
	prog_bar_tween = create_tween()
	prog_bar_tween.tween_property(%ProgBar, "value", progress, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	%ProgBar.show()
	await prog_bar_tween.finished


## Function to add a citation to the interface
func add_citation(cite:Control):
	%CitationCon.show()
	%Citations.add_child(cite)

func clear_citations() -> void:
	%CitationCon.hide()
	for cite in %Citations.get_children():
		cite.queue_free()


## Function to append text to the interface message area
func add_to_message(update:String):
	text_control.text += update


func _on_mouse_entered() -> void:
	%Buttons.show()


func _on_mouse_exited() -> void:
	if valid:
		%Buttons.hide()


var valid:bool = true

func _on_remove_btn_pressed() -> void:
	valid = false
	request_remove.emit(self)


func _on_edit_btn_pressed() -> void:
	%EditPopup.position = Vector2(get_window().position) + global_position
	%EditPopup.popup()
	%EditText.text = text_control.text


func _on_accept_edit_btn_pressed() -> void:
	%EditPopup.hide()
	request_edit.emit(%EditText.text, self)
	text_control.text = %EditText.text


func _on_copy_btn_pressed() -> void:
	var content:String = text_control.text.replace("    ", "\t")
	DisplayServer.clipboard_set(content)


var last_action_block:Control
