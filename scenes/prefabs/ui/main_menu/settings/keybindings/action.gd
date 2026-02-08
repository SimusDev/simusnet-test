extends Button

var action: StringName

signal selected()

func _ready() -> void:
	s_KeyBindings.on_action_changed.connect(_action_changed)
	_action_changed(action)

func _pressed() -> void:
	selected.emit()

func _action_changed(other: StringName) -> void:
	if action == other:
		text = action + " - "
		
		for event in s_KeyBindings.get_actions_events(action):
			text += event.as_text() + "; "
		
