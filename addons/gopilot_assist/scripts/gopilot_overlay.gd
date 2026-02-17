@tool
extends Control

const SETTINGS_DIR:String = "res://addons/gopilot_assist/settings.json"
const SCRIPT_POPUP_OPTIONS:PackedStringArray = ["Explain", "Add comments", "Optimize"]
var SCRIPT_POPUP_FUNCTIONS:Array[Callable] = [explain_code, add_comments_to_code, optimize_code]

var client:HTTPClient = HTTPClient.new()
var settings:Dictionary = {}
var plugin:EditorPlugin

var generating:bool = false
@onready var suggestion_con:Control = %SuggestionCon
@onready var suggestion_window:Control = %SuggestionWindow
@onready var code_suggestion:CodeEdit = %CodeSuggestion

@export var icon:Texture2D
@export var play:Texture2D
@export var stop:Texture2D

@export var chat_requesters:Array[ChatRequester]
@export var code_requesters:Array[ChatRequester]

var completion_context_above:int
var completion_context_below:int

var primary_shortcut:String
var secondary_shortcut:String
var stop_completion:PackedStringArray = ["Escape", "Shift+Tab"]

#region script popup menu options
func _on_popup_index_pressed(index:int):
	SCRIPT_POPUP_FUNCTIONS[index].call()

const EXPLAIN_CODE_PRT := ""

func explain_code():
	
	pass

func add_comments_to_code():
	
	pass

func optimize_code():
	
	pass
#endregion



func _ready() -> void:
	%CodeSuggester.options["stop"] = ["\n"]
	%TranslationStatus.set_status("Idle")
	_setup_confirmation_window()
	_read_settings()
	_bind_code_suggester()
	_setup_popup()
	if EditorInterface.get_script_editor().get_current_editor():
		_setup_script_integration()
	else:
		await EditorInterface.get_script_editor().editor_script_changed
		_setup_script_integration()


func _setup_popup():
	%ScriptPopup.clear()
	for i in SCRIPT_POPUP_OPTIONS.size():
		%ScriptPopup.add_icon_item(icon, SCRIPT_POPUP_OPTIONS[i])
	%ScriptPopup.index_pressed.connect(_on_popup_index_pressed)


func _setup_script_integration():
	var editor := _get_editor()
	EditorInterface.get_script_editor().editor_script_changed.connect(_on_script_changed.unbind(1))
	_on_script_changed()
	%HintsContainer.position = Vector2(-10.0, -53.0)


var gopilot_code_indicator:MenuButton

func _on_script_changed():
	# Creating button for script editor bottom row
	var btn := MenuButton.new()
	btn.name = "TestBtn"
	btn.flat = true
	btn.icon = icon
	btn.tooltip_text = "Gopilot is running"
	var functions:Array[Callable] = [suggest_code, refactor_code, func():_unbind_code_suggester(); %InsertCodeWindow.open_window(%CodeSuggester)]
	var popup:PopupMenu = btn.get_popup()
	popup.add_icon_item(icon, "Generate Completion")
	popup.add_icon_item(icon, "Refactor")
	popup.add_icon_item(icon, "Generate New Code")
	popup.index_pressed.connect(func(index):functions[index].call())
	
	gopilot_code_indicator = btn
	
	var editor := _get_editor()
	var bottom_con = editor.get_parent().get_child(1)
	if bottom_con.has_node("TestBtn"):
		var button = bottom_con.get_node("TestBtn")
		bottom_con.remove_child(button)
		button.queue_free()
	bottom_con.add_child(btn, true)
	bottom_con.move_child(btn, 4)
	if !editor.get_menu().about_to_popup.is_connected(_on_script_popup):
		editor.get_menu().about_to_popup.connect(_on_script_popup)


func _on_script_popup():
	# does not work yet
	#print("popup!!!")
	#var editor := _get_editor()
	#editor.get_menu().add_item("example text")
	pass


func _read_settings():
	_load_settings_file()
	for requester in chat_requesters:
		requester.apply_config(settings["chat_model"])
	for requester in code_requesters:
		requester.apply_config(settings["code_model"])
	completion_context_above = settings["completion_context_above"]
	completion_context_below = settings["completion_context_below"]
	primary_shortcut = settings["primary_shortcut"]
	secondary_shortcut = settings["secondary_shortcut"]


func _input(event: InputEvent) -> void:
	if !EditorInterface.get_script_editor() or !EditorInterface.get_script_editor().get_current_editor():
		return
	if event is InputEventKey and event.is_pressed() and !event.is_echo():
		var keycode:String = event.as_text_keycode()
		if _get_editor().has_focus():
			var code_selected:bool = !_get_editor().get_selected_text().is_empty()
			match keycode:
				primary_shortcut:
					_read_settings()
					accept_event()
					if code_selected:
						_unbind_code_suggester()
						state = STATES.IDLE
						refactor_code()
					else:
						_bind_code_suggester()
						suggest_code()
				secondary_shortcut:
					accept_event()
					if code_selected:
						_unbind_code_suggester()
						%ScriptPopup.popup()
						%ScriptPopup.position = _get_global_cursor_pos()
					else:
						_unbind_code_suggester()
						%InsertCodeWindow.open_window(%CodeSuggester)
				
				"Tab":
					if state != STATES.IDLE and %SuggestionWindow.visible:
						set_process(false)
						accept_event()
						# This calls editor.end_complex_operation()
						_accept_generation()
						_unbind_code_suggester()
				
				"Escape", "Backspace":
					if state != STATES.IDLE and %SuggestionWindow.visible:
						set_process(false)
						accept_event()
						_reject_generation()
						_unbind_code_suggester()
						_get_editor().end_complex_operation()
				_:
					if %SuggestionWindow.visible and state != STATES.IDLE:
						set_process(false)
						accept_event()
						_reject_generation()
						_unbind_code_suggester()
						_get_editor().end_complex_operation()
						pass

func _get_global_cursor_pos() -> Vector2i:
	var editor := _get_editor()
	var editor_line := editor.get_caret_line()
	var editor_column := editor.get_caret_column()
	var caret_pos := editor.get_rect_at_line_column(editor_line, editor_column).position
	return caret_pos + Vector2i(editor.global_position)

func _get_editor() -> CodeEdit:
	return EditorInterface.get_script_editor().get_current_editor().get_base_editor()


func _get_open_script() -> Script:
	return EditorInterface.get_script_editor().get_current_script()


func _get_selected_code() -> String:
	return EditorInterface.get_script_editor().get_current_editor().get_base_editor().get_selected_text()


func _reject_generation():
	if state == STATES.GENERATING:
		%CodeSuggester.reconnect()
	state = STATES.IDLE
	var editor := _get_editor()
	_close_suggestion()
	var code_scroll := editor.scroll_vertical
	editor.text = code_before_completion.replace("\uFFFF", "")
	editor.set_caret_line(last_line)
	editor.set_caret_column(last_column)
	editor.scroll_vertical = code_scroll
	editor.end_complex_operation()

# This function
func _accept_generation() :
	state = STATES.IDLE
	var editor := _get_editor()
	var scroll_v := editor.scroll_vertical
	var scroll_h := editor.scroll_horizontal
	editor.text = code_before_completion.replace("\uFFFF", "")
	editor.insert_text(generated_code.replace("\uFFFF", "") ,last_line, last_column)
	#var split:PackedStringArray = code_before_completion.split("\uFFFF")
	#var before_cursor:String = split[0].replace("\uFFFF", "")
	#var after_cursor:String = split[1].replace("\uFFFF", "")
	#editor.text = before_cursor + generated_code.replace("    ", "\t") + after_cursor
	editor.scroll_vertical = scroll_v
	editor.scroll_horizontal = scroll_h
	editor.set_caret_line(last_line)
	editor.set_caret_column(last_column)
	editor.end_complex_operation()
	EditorInterface.get_script_editor().get_current_editor().get_base_editor().update_configuration_warnings()
	EditorInterface.get_script_editor().get_current_editor().update_configuration_warnings()
	_close_suggestion()


# When the generation is finished, show a success message and close the suggestion
func _generation_finished(full_text:String):
	%SuggestionStatus.text = "[color=green]Done[/color]"
	%HintContainer.show()
	%SuggestionStatus.modulate = Color.GREEN
	state = STATES.DONE


enum STATES {IDLE, GENERATING, DONE}
var state:STATES = STATES.IDLE

var code_before_completion:String = ""
var generated_code:String = ""

var listening_for_shortcut:bool = false


func show_suggestion_window() -> void:
	suggestion_window.show()


func hide_suggestion_window() -> void:
	suggestion_window.hide()


func refactor_code() -> void:
	_unbind_code_suggester()
	var editor:CodeEdit = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
	var selected_code:String = editor.get_selected_text()
	%CodeRefactorWindow.edit_code(selected_code, %CodeSuggester, true)


func set_plugin(_plugin:EditorPlugin) -> void:
	plugin = _plugin

#region code completion

func suggest_code() -> void:
	code_suggestion.size = Vector2i.ZERO
	_bind_code_suggester()
	set_process(true)
	if state == STATES.GENERATING:
		return
	newline_amount = 0
	#plugin.open_gopilot_dock()
	%SuggestionStatus.text = "[color=yellow][pulse]Loading[wave freq=5 amp=30]..."
	%SuggestionStatus.modulate = Color.WHITE
	%CodeSuggestion.text = ""
	%CodeSuggestion.set_caret_line(0)
	state = STATES.GENERATING
	suggestion_window.show()
	generated_code = ""
	var editor:CodeEdit = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
	
	
	editor.update_configuration_warnings()
	editor.syntax_highlighter.clear_highlighting_cache()
	editor.cancel_code_completion()
	code_suggestion.add_theme_font_override("font", editor.get_theme_font("font"))
	code_suggestion.add_theme_font_size_override("font_size", editor.get_theme_font_size("font_size"))
	var line:int = editor.get_caret_line()
	var column:int = editor.get_caret_column()
	var full_text:String = editor.get_text_with_cursor_char(line, column)
	code_before_completion = full_text
	var cursor_character:String = "\uFFFF"
	var split_code:PackedStringArray = full_text.split(cursor_character)
	var top_lines := split_code[0].split("\n")
	var bottom_lines := split_code[1].split("\n")
	if top_lines.size() > completion_context_above:
		var new_lines:PackedStringArray = []
		for i in completion_context_above:
			new_lines.append(top_lines[(-completion_context_above) + i])
		top_lines = new_lines
	if bottom_lines.size() > completion_context_below:
		var new_lines:PackedStringArray = []
		for i in completion_context_below:
			new_lines.append(bottom_lines[i])
		bottom_lines = new_lines
	var before:String
	for l in top_lines:
		before += l
		if l != top_lines[-1]:
			before += "\n"
	var after:String
	for l in bottom_lines:
		after += l
		if l != bottom_lines[-1]:
			after += "\n"
	if settings["multiline_completion"] == false:
		%CodeSuggester.options["stop"] = ["\n"]
	else:
		%CodeSuggester.options["stop"] = []
	#if settings["code_model_has_completion"]:
	%CodeSuggester.fill_in_the_middle(before, after, true)
	#else:
		#%CodeSuggester.fill_in_the_middle_fallback(before, true)
	
	var front_line:String = full_text.split("\uFFFF")[0].split("\n")[-1]
	var end_line:String = full_text.split("\uFFFF")[1].split("\n")[0]
	code_suggestion.text = front_line + end_line
	var pos := editor.get_rect_at_line_column(editor.get_caret_line(), 0).position + Vector2i(editor.get_global_rect().position)
	var _size:Vector2 = editor.get_global_rect().end - Vector2(pos)
	suggestion_window.global_position = pos
	suggestion_window.size = _size
	code_suggestion.position = Vector2(-8.0, -4.0)
	last_line = line
	last_column = column
	
	# Packs action into bigger operation
	editor.begin_complex_operation()

const suggestion_offset:Vector2 = Vector2(-8.0, -4.0)
const INITIAL_SIZE:Vector2i = Vector2i(540, 40)

var longest_line_pos:Vector2i = Vector2i.ZERO


func get_line_height(line:int, editor:CodeEdit) -> int:
	var first_visible_line:int = editor.get_first_visible_line()
	var last_visible_line:int = editor.get_last_full_visible_line()
	var character_height:int = editor.get_rect_at_line_column(first_visible_line, 0).size.y
	var first_visible_line_height:int = editor.get_rect_at_line_column(first_visible_line, 0).position.y
	return first_visible_line_height + (line - first_visible_line) * character_height


func _process(delta: float) -> void:
	if !EditorInterface.get_script_editor().get_current_editor():
		return
	var editor:CodeEdit = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
	var _pos:Vector2
	var last_visible_line:int = editor.get_last_full_visible_line()
	var line_pos := get_line_height(last_line, editor)
	var bottom_preview_pos := get_line_height(last_visible_line + 2, editor)
	_pos = Vector2(editor.get_rect_at_line_column(last_visible_line , 0).position.x, min(bottom_preview_pos, line_pos))
	var suggestion_line:int = code_suggestion.get_line_count() - 1
	var suggestion_column:int = code_suggestion.get_line(suggestion_line).length() - 1
	if suggestion_column > longest_line_pos.x:
		longest_line_pos = Vector2i(suggestion_column, suggestion_line)
	var size_x:int = code_suggestion.get_rect_at_line_column(longest_line_pos.y, longest_line_pos.x).end.x
	var size_y:int = code_suggestion.get_rect_at_line_column(suggestion_line, suggestion_column + 1).end.y
	var _size := Vector2(size_x, size_y)
	var editor_global_rect:Rect2i = editor.get_global_rect()
	
	suggestion_window.position = editor_global_rect.position
	suggestion_window.size = editor_global_rect.size
	
	suggestion_con.position = _pos
	code_suggestion.position = suggestion_offset


var last_shortcut_pressed:String = ""

var unhandled_generation:String = ""


func _close_suggestion():
	code_suggestion.text = ""
	%HintContainer.hide()
	%SuggestionCon.size = INITIAL_SIZE
	longest_line_pos = Vector2i.ZERO
	suggestion_window.hide()
	state = STATES.IDLE
	set_process(false)


var last_line:int
var last_column:int

var code_highlighter_tween:Tween


var newline_amount:int = 0


func _update_suggestion(word:String):
	%SuggestionStatus.text = "[color=yellow][pulse]Writing[wave freq=5 amp=30]..."
	generated_code += word
	unhandled_generation += word
	var editor:CodeEdit = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
	var scroll_v := editor.scroll_vertical
	var scroll_h := editor.scroll_horizontal
	
	var front_line:String = code_before_completion.split("\uFFFF")[0].split("\n")[-1]
	var end_line:String = code_before_completion.split("\uFFFF")[1].split("\n")[0]
	code_suggestion.text = front_line + generated_code.replace("    ", "\t") + end_line
	var suggestion_line:int = code_suggestion.get_line_count() - 1
	var suggestion_column:int = code_suggestion.get_line(suggestion_line).length() - 1
	var size_x:int = code_suggestion.get_rect_at_line_column(longest_line_pos.y, longest_line_pos.x).end.x
	var size_y:int = code_suggestion.get_rect_at_line_column(suggestion_line, suggestion_column + 1).end.y
	var _size := Vector2(size_x, size_y)
	suggestion_con.size = _size# + Vector2(10, 5)
	suggestion_con.size = code_suggestion.size
	if "\n" in unhandled_generation:
		var newlines_in_generation:int = unhandled_generation.count("\n")
		newline_amount += newlines_in_generation
		var newlines:String
		for i in newline_amount:
			newlines += "\n"
		editor.text = code_before_completion.split("\uFFFF")[0] + end_line + newlines + code_before_completion.split("\uFFFF")[1].trim_prefix(end_line)
		editor.scroll_vertical = scroll_v
		editor.scroll_horizontal = scroll_h
		editor.set_caret_line(last_line)
		editor.set_caret_column(last_column)
		unhandled_generation = ""

#endregion

func _load_settings_file():
	if !FileAccess.file_exists(SETTINGS_DIR):
		push_error("No settings file found!")
		return
	var file := FileAccess.open(SETTINGS_DIR, FileAccess.READ)
	var text := file.get_as_text()
	var data:Dictionary = JSON.parse_string(text)
	settings = data
	file.close()


func _bind_code_suggester():
	if !%CodeSuggester.new_word.is_connected(_update_suggestion):
		%CodeSuggester.new_word.connect(_update_suggestion)
	if !%CodeSuggester.message_end.is_connected(_generation_finished):
		%CodeSuggester.message_end.connect(_generation_finished)


func _unbind_code_suggester():
	if %CodeSuggester.new_word.is_connected(_update_suggestion):
		%CodeSuggester.new_word.disconnect(_update_suggestion)
	if %CodeSuggester.message_end.is_connected(_generation_finished):
		%CodeSuggester.message_end.disconnect(_generation_finished)


func open_translation_panel(path:String):
	_unbind_code_suggester()
	%TranslationWindow.open_csv_file(path, true)


signal request_decided(confirmed:bool)


func _setup_confirmation_window():
	%ConfirmationWindow.confirmed.connect(request_decided.emit.bind(true))
	%ConfirmationWindow.canceled.connect(request_decided.emit.bind(false))


func request_action(action:String) -> bool:
	%ConfirmationWindow.size = Vector2i.ZERO
	%ConfirmationWindow.dialog_text = action
	%ConfirmationWindow.popup()
	return await request_decided
