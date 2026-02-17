@tool
extends ConfirmationDialog


const CLOSE_SIZE := Vector2i(500, 0)
const OPEN_SIZE := Vector2i(700, 600)

var editor:CodeEdit
var chat:ChatRequester


func _ready() -> void:
	%BottomControls.hide()



func open_window(_chat:ChatRequester):
	borderless = true
	newly_opened = true
	var main_window_pos := Vector2(get_tree().get_root().position)
	get_ok_button().hide()
	get_cancel_button().hide()
	%RefinePrompt.set_generating(false)
	%WritePrompt.set_generating(false)
	_chat.stop_generation()
	chat = _chat
	if !chat.new_word.is_connected(_on_new_word):
		chat.new_word.connect(_on_new_word)
	if !chat.message_end.is_connected(_on_message_end):
		chat.message_end.connect(_on_message_end)
	editor = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
	var window_pos:Vector2
	var editor_line := editor.get_caret_line()
	var editor_column := editor.get_caret_column()
	var caret_rect := editor.get_rect_at_line_column(editor_line, editor_column)
	window_pos = editor.get_global_rect().position + Vector2(caret_rect.position) - Vector2(0.0, 80.0) + main_window_pos
	position = window_pos
	size = CLOSE_SIZE
	show()
	%Code.syntax_highlighter = editor.syntax_highlighter
	%WritePrompt.grab_text_focus()


const REFINE_FUNCTION_PRT := "This is my script so far:
```gdscript
{.full_script}
```
And this is the code I want to modify:
```gdscript
{.code}
```
{.instruction}

Please only respond with your code like this:
```gdscript
# Your code here (e.g. functions and comments etc.)
```
RESPOND ONLY WITH YOUR CODE! DO NOT WRITE ANYTHING ABOVE OR BELOW YOUR CODE!!!"

const WRITE_FUNCTION_PRT := "This is my script so far:
```gdscript
{.full_script}
```

{.instruction}"



var COMMON := preload("res://addons/gopilot_utils/scripts/common.gd").new()


var raw_response:String = ""

func _on_new_word(word:String):
	var scroll_v:float= %Code.scroll_vertical
	var scroll_h:float = %Code.scroll_horizontal
	%RefinePrompt.set_status("Writing")
	raw_response += word
	%Code.text = COMMON.trim_code_block(raw_response)
	%Code.scroll_vertical = scroll_v
	%Code.scroll_horizontal = scroll_h
	get_ok_button().show()


func _on_message_end(full_message:String):
	%RefinePrompt.set_status("Idle")
	%RefinePrompt.set_generating(false)
	%RefinePrompt.set_interactable(true)
	%WritePrompt.set_generating(false)
	%WritePrompt.set_interactable(true)



func _on_generation_interrupted():
	chat.stop_generation()
	_on_message_end("")


var newly_opened:bool = true



func _on_write_prompt_submitted(prompt:String) -> void:
	get_cancel_button().show()
	get_ok_button().hide()
	raw_response = ""
	%RefinePrompt.set_status("Loading")
	%BottomControls.show()
	var current_code:String = editor.text
	var final_prompt := WRITE_FUNCTION_PRT.replace("{.full_script}", current_code).replace("{.instruction}", prompt)
	%Code.text = ""
	%RefinePrompt.set_interactable(false)
	chat.options["stop"] = []
	chat.generate(final_prompt, true, false, false, "", "```gdscript\n")
	#chat.send_message(final_prompt)
	#chat.send_message("```gdscript\n", ChatRequester.chat_role.ASSISTANT)
	#chat.start_response()
	if newly_opened:
		borderless = false
		var main_window := get_tree().get_root()
		var final_pos:Vector2i = main_window.position + main_window.size / 2 - OPEN_SIZE / 2
		get_tree().create_tween().tween_property(self, ^"position", final_pos, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		get_tree().create_tween().tween_property(self, ^"size", OPEN_SIZE, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	newly_opened = false


func _on_refine_prompt_submitted(prompt:String) -> void:
	get_cancel_button().show()
	get_ok_button().hide()
	raw_response = ""
	%RefinePrompt.set_status("Loading")
	%BottomControls.show()
	var current_code:String = editor.text
	var final_prompt := REFINE_FUNCTION_PRT.replace("{.full_script}", current_code).replace("{.instruction}", prompt).replace("{.code}", %Code.text)
	%Code.text = ""
	%RefinePrompt.set_interactable(false)
	chat.generate(final_prompt, true, false, false, "", "```gdscript\n")


func _on_accept_btn_pressed() -> void:
	_close_window()
	
	var editor_line := editor.get_caret_line()
	var editor_column := editor.get_caret_column()
	var code_with_cursor:String = editor.get_text_with_cursor_char(editor_line, editor_column)
	var split_code := code_with_cursor.split("\uFFFF")
	var scroll_v := editor.scroll_vertical
	var scroll_h := editor.scroll_horizontal
	editor.text = split_code[0] + %Code.text + split_code[1]
	editor.scroll_vertical = scroll_v
	editor.scroll_horizontal = scroll_h
	editor.set_caret_line(editor_line)
	editor.set_caret_column(editor_column)


func _close_window():
	%WritePrompt.clear_text()
	%RefinePrompt.clear_text()
	%BottomControls.hide()
	hide()
	chat.new_word.disconnect(_on_new_word)
	chat.message_end.disconnect(_on_message_end)
	chat.stop_generation()


func _on_deny_btn_pressed() -> void:
	_close_window()
