@tool
extends Control

## Defines the type of text field
enum text_types {
	SINGLE_LINE,	## Uses a [LineEdit]
	MULTI_LINE,		## Uses a [TextEdit] for multiline editing,
	MULTI_LINE_CODE,## Uses a [CodeEdit] for code syntac highlighting
	NONE			## Hides every text field, so that it's just the send button
	}

## Emitted when the send button with [member send_button_send_text] is pressed
signal prompt_submitted(prompt:String)

## Emitted when the send button with [member send_button_stop_text] is pressed
signal stop_pressed

## Emitted whenever the user changes the text
signal text_changed(text:String)

## Intenal variable. Contains all types of text fields
@onready var text_fields:Array[Control] = [%LineEdit, %TextEdit, %CodeEdit, %NoText]

## What type of text editor to use
@export var text_type:text_types = text_types.MULTI_LINE:
	set(new):
		text_type = new
		for field in text_fields.size():
			if field == new:
				text_fields[field].show()
			else:
				text_fields[field].hide()

## The text displayed when field is empty
@export var placeholder_text:String = "Ask anything...":
	set(new):
		placeholder_text = new
		for edit in text_fields:
			edit.placeholder_text = new

## Puts text into field before user types something
@export var initial_text:String = "":
	set(new):
		initial_text = new
		for edit in text_fields:
			edit.text = new

## When true, clears text field when the send button is pressed
@export var clear_text_on_send:bool = true

## The tooltip of the text field
@export_multiline var text_field_tooltip:String = "":
	set(new):
		text_field_tooltip = new
		for field in text_fields:
			field.tooltip_text = new


@export var status_indicator:bool = true:
	set(new):
		status_indicator = new
		%StatusIndicator.visible = new

@export var accepted_dropped_data_types:PackedStringArray

@export var clear_suggestions_when_submitted:bool = true

@export var panel_background:StyleBox:
	set(new):
		if new != panel_background:
			panel_background = new
			if is_node_ready():
				if new == null:
					%BG.remove_theme_stylebox_override("read_only")
				else:
					%BG.add_theme_stylebox_override("read_only", new)

@export_group("Multiline", "multiline_")

@export var multiline_text_wrapping:TextEdit.LineWrappingMode = TextEdit.LineWrappingMode.LINE_WRAPPING_BOUNDARY:
	set(new):
		multiline_text_wrapping = new
		if is_node_ready():
			for field in text_fields:
				if field is TextEdit:
					field.wrap_mode = new
		else:
			ready.connect(func():
				for field in text_fields:
					if field is TextEdit:
						field.wrap_mode = new
			)

## The number of lines to fill before locking in the size of the text field
@export var multiline_lines_until_scroll:int = 6:
	set(new):
		multiline_lines_until_scroll = new
		if is_node_ready():
			_update_minimum_size()

## The number of pixels to add to the height of the text field when it expands
@export var multiline_line_expand_padding:int = 5:
	set(new):
		multiline_line_expand_padding = new
		if is_node_ready():
			_update_minimum_size()

@export var multiline_default_minimum_height:int = 50:
	set(new):
		multiline_default_minimum_height = new
		if is_node_ready():
			_update_minimum_size()

@export_group("Send Button", "send_button_")

## Text of the send button when idle
@export var send_button_send_text:String = "SEND":
	set(new):
		send_button_send_text = new
		if is_node_ready():
			%SendBtn.text = new

## Icon of the send button when idle
@export var send_button_send_icon:Texture2D = preload("res://addons/gopilot_utils/textures/Play.png"):
	set(new):
		send_button_send_icon = new
		if is_node_ready():
			%SendBtn.icon = new

## Text of the send button when generating
@export var send_button_stop_text:String = "STOP"

## Icon of the send button when generating
@export var send_button_stop_icon:Texture2D = preload("res://addons/gopilot_utils/textures/Stop.png")

## When the text field is focussed and one of the shortcuts is pressed, presses button
@export var send_button_keyboard_shortcuts:PackedStringArray = ["Ctrl+Enter"]

## Text shown when hovering over send button
@export_multiline var send_button_tooltip:String = "Send a message to a model":
	set(new):
		if is_node_ready():
			%SendBtn.tooltip_text = new
		send_button_tooltip = new

## When true, disables send button when text field is empty
@export var disable_button_when_empty:bool = true:
	set(new):
		disable_button_when_empty = new
		if is_node_ready():
			%SendBtn.set_disabled(new and text_fields[text_type].text.is_empty())
		else:
			ready.connect(%SendBtn.set_disabled.bind(new and text_fields[text_type].text.is_empty()))

## When true, disables the text field when the send button is pressed
@export var disable_text_field_on_submit:bool = true

@export_group("Background", "background")

@export_range(0.0, 100.0, 1.0, "hide_slider") var background_margin:int = 2:
	set(new):
		background_margin = new
		if is_node_ready():
			var margins:PackedStringArray = ["margin_top", "margin_bottom", "margin_left", "margin_right"]
			for margin in margins:
				%PromptMargin.add_theme_constant_override(margin, new)


func _ready() -> void:
	%PromptDragWidget.hide()
	set_process_input(false)
	for field in text_fields.size():
		var f:Control = text_fields[field]
		f.tooltip_text = text_field_tooltip
		f.placeholder_text = placeholder_text
		f.text = initial_text
		if field == text_type:
			f.show()
		else:
			f.hide()
	if initial_text.is_empty():
		%SendBtn.disabled = true
	%SendBtn.tooltip_text = send_button_tooltip
	%SendBtn.text = send_button_send_text
	%SendBtn.icon = send_button_send_icon
	%StatusIndicator.visible = status_indicator
	for field in text_fields:
		if field is TextEdit:
			field.wrap_mode = multiline_text_wrapping
			field.scroll_fit_content_height = true
	resized.connect(_update_minimum_size)


func can_drop_data(at_position:Vector2, data:Variant, _control:Control) -> bool:
	if data is Dictionary:
		#print(data[data["type"]])
		return data["type"] in accepted_dropped_data_types
	#print(data)
	if data is String:
		return true
	return false


func drop_data(at_positon:Vector2, data:Variant, control:Control) -> void:
	if data is String:
		%PromptDragWidget.hide()
		set_process(false)
		return
	match data["type"]:
		"script_list_element": print(data["script_list_element"].get_functions())


## Returns the text in the text field
func get_text() -> String:
	return text_fields[text_type].text


## Sets the text of the text field
func set_text(text:String) -> void:
	for field in text_fields:
		field.text = text


func clear_text() -> void:
	for filed in text_fields:
		filed.text = initial_text

## Internal variable. Determines if the ChatRequester is generating or not
var generating:bool = false

## Sets the interactability of the send button and the text field. Useful when you don't want the user to interact with the interface
func set_interactable(interactable:bool, text_field_interactable:bool = false):
	if text_field_interactable:
		for field in text_fields:
			field.editable = interactable
	%SendBtn.disabled = !interactable

func _on_send_btn_pressed() -> void:
	var field:Control = text_fields[text_type]
	var prompt:String = field.text
	if !generating:
		set_generating(true)
		prompt_submitted.emit(prompt)
		_update_minimum_size()
		if clear_suggestions_when_submitted:
			clear_suggestions()
	else:
		stop_pressed.emit()
		set_generating(false)

## Sets [member generating] and applies to interface
func set_generating(_generating:bool, change_button:bool = true, change_text_field:bool = true):
	var field:Control = text_fields[text_type]
	if _generating:
		set_status("Loading")
		if change_button:
			%SendBtn.text = send_button_stop_text
			%SendBtn.icon = send_button_stop_icon
		if change_text_field:
			if disable_text_field_on_submit:
				for f in text_fields:
					f.editable = false
			if clear_text_on_send:
				field.text = ""
	else:
		set_status("Idle")
		if change_button:
			%SendBtn.text = send_button_send_text
			%SendBtn.icon = send_button_send_icon
		if change_text_field:
			for f in text_fields:
				f.editable = true
		field.grab_focus()
	for sugg:Button in %Suggestions.get_children():
		sugg.disabled = _generating
	generating = _generating

func _on_text_gui_input(event:InputEvent):
	if not text_fields[text_type].has_focus():
		return
	
	if event is InputEventKey and not event.is_echo() and event.is_pressed():
		var keycode:String = event.as_text_keycode()
		
		# Early exit if no matching shortcut is found
		if keycode in send_button_keyboard_shortcuts:
			accept_event()
			_on_send_btn_pressed()
			return


const SCRIPT_ICON:Texture2D = preload("res://addons/gopilot_utils/textures/Script.png")

## Adds a suggestion button to the suggestion list.
## Suggestions are scrollable
## See also [method add_to_suggestion] and [method set_suggestion]
func add_suggestion(title:String, prompt:String, prefix:String = "Prompt: ", icon:Texture2D = SCRIPT_ICON) -> void:
	var suggestion := %SuggestionSample.duplicate()
	suggestion.text = title
	suggestion.tooltip_text = prefix + prompt
	suggestion.icon = icon
	suggestion.set_meta("prompt", prompt)
	suggestion.pressed.connect(_on_suggestion_pressed.bind(prompt))
	%SuggestionsCon.show()
	%Suggestions.add_child(suggestion)
	suggestion.show()





## Adds text to a given suggestion prompt based on [param index]
## DOES NOT UPDATE THE TITLE, JUST THE PROMPT (and tooltip)
func add_to_suggestion(index:int = -1, addition:String = ""):
	var sugg:Button = %Suggestions.get_child(index)
	sugg.text += addition


## Sets the suggestion button text and prompt based on the provided [param index]
func set_suggestion(index:int, title:String, prompt:String, prefix:String = "Prompt: ") -> void:
	var sugg:Button = %Suggestions.get_child(index)
	sugg.text = title
	sugg.tooltip_text = prefix + prompt


func clear_suggestions() -> void:
	for child in %Suggestions.get_children():
		child.queue_free()
	%SuggestionsCon.hide()


## Forwards the call to the Status Indicator
func set_status(status:String) -> void:
	%StatusIndicator.set_status(status)


## The active text field (defined in [member text_type]) grabs the focus and puts the caret at a specific location
## When [param caret_column] is -1, it puts the caret at the end of the text
func grab_text_focus(caret_column:int = -1, caret_line:int = -1):
	var field:Control = text_fields[text_type]
	var text_length:int = field.text.length()
	
	if caret_column == -1:
		caret_column = text_length
	
	if field is LineEdit:
		field.caret_column = caret_column
	elif field is TextEdit:
		field.set_caret_column(caret_column)
		field.set_caret_line(caret_line)
	field.release_focus()
	field.grab_focus()


func has_text_focus() -> bool:
	return text_fields[text_type].has_focus()


func _on_suggestion_pressed(prompt:String):
	prompt_submitted.emit(prompt)
	_update_minimum_size()
	set_generating(true)


## Moves prompt preview when prompt example dragged
func _input(event: InputEvent) -> void:
	%PromptDragWidget.global_position = get_global_mouse_position()
	if event is InputEventMouseButton:
		if !event.is_pressed():
			%PromptDragWidget.hide()
			set_process_input(false)


func suggestion_get_drag_data(at_position:Vector2, button:Button) -> Variant:
	%PromptDragWidget.show()
	%PromptDragWidget.size.y = 0.0
	%PromptDragWidget.text = button.tooltip_text
	set_process_input(true)
	return button.get_meta("prompt")


func set_syntax_highlighter(syntax:SyntaxHighlighter):
	for f in text_fields:
		if f is TextEdit:
			f.syntax_highlighter = syntax


func _update_minimum_size():
	if text_fields[text_type] is TextEdit:
		var text_edit:TextEdit = text_fields[text_type]
		var visible_lines := text_edit.get_total_visible_line_count()
		var clamp_size:bool = visible_lines > multiline_lines_until_scroll
		
		var max_height:int = text_edit.get_line_height() * multiline_lines_until_scroll + multiline_line_expand_padding
		
		if clamp_size:
			text_edit.scroll_fit_content_height = false
			text_edit.custom_minimum_size.y = float(max_height)
		else:
			text_edit.scroll_fit_content_height = true
			text_edit.custom_minimum_size.y = 0.0


func _on_text_changed():
	text_changed.emit(text_fields[text_type].text)
	%SendBtn.disabled = text_fields[text_type].text.is_empty()
	_update_minimum_size()
