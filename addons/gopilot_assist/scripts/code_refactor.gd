@tool
extends ConfirmationDialog


var coder:ChatRequester

var generating:bool = false

const SETTINGS_DIR := "res://addons/gopilot_assist/settings.json"
@export_multiline var refactor_prompts:PackedStringArray = []

@export var RELOAD_ICON:Texture2D
@export var SEND_ICON:Texture2D
@export var STOP_ICON:Texture2D

var settings:Dictionary

func _ready() -> void:
	%PromptField.clear_suggestions()
	await get_tree().create_timer(0.5).timeout
	for prompt in refactor_prompts:
		%PromptField.add_suggestion(prompt.split("\n")[0], prompt.trim_prefix(prompt.split("\n")[0] + "\n"))
	hide()


func _on_confirmed():
	if %CodeAfter.text == "":
		_set_warning("Press 'Send' to generate a revised version of your code")
		return
	_set_warning("")
	var editor := _get_editor()
	var scroll_v:int = editor.scroll_vertical
	var scroll_h:int = editor.scroll_horizontal
	var pos := Vector2i(editor.get_caret_column(), editor.get_caret_line())
	var before_code := editor.get_text_with_cursor_char(selection_start.y, selection_start.x).split("\uFFFF")[0].trim_suffix(%CodeBefore.text)
	var after_code := editor.get_text_with_cursor_char(selection_end.y, selection_end.x).split("\uFFFF")[1]
	editor.begin_complex_operation()
	editor.text = before_code + %CodeAfter.text + after_code
	hide()
	editor.scroll_vertical = scroll_v
	editor.scroll_horizontal = scroll_h
	editor.set_caret_line(pos.y)
	editor.set_caret_column(pos.x)
	editor.end_complex_operation()


func _set_warning(warning:String):
	%WarningLabel.text = warning
	if warning == "":
		%WarningLabel.hide()
	else:
		%WarningLabel.show()

var selection_start:Vector2i
var selection_end:Vector2i


func edit_code(code:String, requester:ChatRequester, popup:bool = true) -> void:
	settings = str_to_var(FileAccess.get_file_as_string(SETTINGS_DIR))
	var suggestions:Dictionary = settings["refactor_prompts"]
	_add_recommendations(suggestions)
	var editor := _get_editor()
	selection_start = Vector2i(editor.get_selection_origin_column(), editor.get_selection_origin_line())
	selection_end = Vector2i(editor.get_selection_to_column(), editor.get_selection_to_line())
	var scroll_v := editor.scroll_vertical
	var scroll_h := editor.scroll_horizontal
	var caret_pos := Vector2i(editor.get_caret_column(), editor.get_caret_line())
	coder = requester
	if !coder.message_end.is_connected(_on_message_end):
		coder.message_end.connect(_on_message_end)
	%CodeAfter.text = ""
	%CodeBefore.text = code
	_set_editor_style()
	if popup:
		_set_warning("")
		popup()
		%PromptField.grab_text_focus()
	_on_code_after_text_changed()
	_on_code_before_text_changed()


func _add_recommendations(recommendations:Dictionary):
	%PromptField.clear_suggestions()
	for title in recommendations:
		%PromptField.add_suggestion(title, recommendations[title])


func _get_editor() -> CodeEdit:
	return EditorInterface.get_script_editor().get_current_editor().get_base_editor()


func _set_editor_style():
	var editor := _get_editor()
	for i:CodeEdit in [%CodeAfter, %CodeBefore]:
		i.syntax_highlighter = editor.syntax_highlighter.duplicate()
		i.add_theme_font_size_override("font_size", editor.get_theme_font_size("font_size"))


func _on_new_word(word:String) -> void:
	%PromptField.set_status("Writing")
	var scroll:Vector2i = Vector2i(%CodeAfter.scroll_horizontal, %CodeAfter.scroll_vertical)
	%CodeAfter.text += word
	#var cleaned_up_code:String = %CodeAfter.text.replace("    ", "\t").replace("```gdscript\n", "").replace("\n```", "")
	#%CodeAfter.text = cleaned_up_code
	%CodeAfter.scroll_horizontal = scroll.x
	%CodeAfter.scroll_vertical = scroll.y


func _on_message_end(full_code:String) -> void:
	if coder.is_connected("new_word", _on_new_word):
		coder.disconnect("new_word", _on_new_word)
	coder.options.erase("stop")
	%PromptField.set_generating(false)


func _rewrite_code(prompt:String) -> void:
	if prompt == "":
		_set_warning("Enter an code instruction in the bottom and then press 'Send'")
		return
	_set_warning("")
	%CodeAfter.text = ""
	coder.options["stop"] = ["\n```"]
	coder.generate(
"This is the code I have written
```gdscript
{.code}
```
{.instruction}"\
.replace("{.instruction}", prompt).replace("{.code}", %CodeBefore.text),
		true, false, false, "", "```gdscript\n"
		)
	if !coder.new_word.is_connected(_on_new_word):
		coder.new_word.connect(_on_new_word)


func _on_canceled() -> void:
	%CodeAfter.text = ""
	%CodeBefore.text = ""


func _on_code_before_text_changed() -> void:
	var lines:int= %CodeBefore.get_line_count()
	if lines == 1:
		%BeforeLineCount.text = "Line: " + str(lines)
	else:
		%BeforeLineCount.text = "Lines: " + str(lines)
	var chars:int = %CodeBefore.text.length()
	if chars == 1:
		%BeforeCharacterCount.text = "Char: " + str(chars)
	else:
		%BeforeCharacterCount.text = "Chars: " + str(chars)


func _on_code_after_text_changed() -> void:
	var lines:int = %CodeAfter.get_line_count()
	if lines == 1:
		%AfterLineCount.text = "Line: " + str(lines)
	else:
		%AfterLineCount.text = "Lines: " + str(lines)
	var chars:int = %CodeAfter.text.length()
	if chars == 1:
		%AfterCharacterCount.text = "Char: " + str(chars)
	else:
		%AfterCharacterCount.text = "Chars: " + str(chars)


func _on_prompt_submitted(prompt: String) -> void:
	_rewrite_code(prompt)


func _on_prompt_field_stop_pressed() -> void:
	coder.stop_generation()
	coder.options.erase("stop")
