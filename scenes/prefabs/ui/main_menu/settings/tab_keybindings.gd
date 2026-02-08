extends Control

@export var _action_scene: PackedScene
@export var _container: Control

@onready var sd_ui_control_search: SD_UIControlSearch = $SD_UIControlSearch

@onready var fade: ColorRect = $Fade
@onready var press_any_key_label: Label = $Fade/PressAnyKeyLabel
@onready var button_ok: Button = $Fade/Buttons/ButtonOK

@export var _buttons: Array[Button]

var _selected_action: StringName
var _selected_event: InputEvent

func _ready() -> void:
	button_ok.hide()
	fade.hide()
	
	for action in s_KeyBindings.get_actions():
		var ui: Control = _action_scene.instantiate()
		ui.selected.connect(_bind_selected.bind(action))
		ui.action = action
		_container.add_child(ui)
		sd_ui_control_search.bind(action, ui)
	
	set_process_input(false)
	
	for button in _buttons:
		button.pressed.connect(_on_button_pressed.bind(button))
		

func _on_button_pressed(button: Button) -> void:
	match button.name:
		"ButtonReset":
			s_KeyBindings.reset_action(_selected_action)
			_on_hidden()
		"ButtonOK":
			s_KeyBindings.bind_action(_selected_action, [_selected_event])
			_on_hidden()
		"ButtonCancel":
			_on_hidden()

func _bind_selected(action: StringName) -> void:
	press_any_key_label.text = "Press any key..."
	_selected_action = action
	fade.show()
	press_any_key_label.show()
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if !is_visible_in_tree():
		return
	
	for button in _buttons:
		if button.is_hovered():
			return
	
	if event is InputEventKey or event is InputEventMouseButton:
		_selected_event = event
		press_any_key_label.text = event.as_text()
		button_ok.show()

func _on_press_any_key_ok_pressed() -> void:
	button_ok.hide()
	fade.hide()
	press_any_key_label.hide()
	set_process_input(false)
	s_KeyBindings.bind_action(_selected_action, [_selected_event])

func _on_hidden() -> void:
	fade.hide()
	press_any_key_label.hide()
	button_ok.hide()
	set_process_input(false)
	
