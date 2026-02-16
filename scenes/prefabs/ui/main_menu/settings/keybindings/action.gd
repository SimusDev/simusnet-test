extends Panel

var action: StringName


@onready var label_action_name: Label = %LabelActionName
@onready var label_action_keys: RichTextLabel = %LabelActionKeys
@onready var button: Button = %Button

signal selected()

func _ready() -> void:
	s_KeyBindings.on_action_changed.connect(_action_changed)
	_action_changed(action)
	
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	selected.emit()

func _action_changed(other: StringName) -> void:
	if action == other:
		label_action_name.text = action
		
		label_action_keys.text = ""
		var action_events = s_KeyBindings.get_actions_events(action)
		for event in action_events:
			label_action_keys.text += event.as_text()
			if action_events.size() > 1:
				label_action_keys.text += "; "
		
