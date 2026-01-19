extends Button

var action: R_InteractAction

func _ready() -> void:
	if !action:
		return
	
	text = action.name

func set_selected(value: bool) -> void:
	disabled = value
