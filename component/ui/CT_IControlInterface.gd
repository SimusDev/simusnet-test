extends Node
class_name CT_IControlInterface

@export var target: Control

@export var input_type: INPUT_TYPE = INPUT_TYPE.DISABLED
@export var input_action: StringName = ""
@export var hide_at_start: bool = false
@export var close_on_escape: bool = true
@export var when_last_interface: bool = true

enum INPUT_TYPE {
	DISABLED,
	PRESS,
	JUST_PRESS,
}

func _input(event: InputEvent) -> void:
	if target.is_visible_in_tree():
		if close_on_escape:
			if Input.is_action_just_pressed(SimusDev.ui.ACTION_CLOSE_MENU):
				target.hide()
	
	if input_type == INPUT_TYPE.DISABLED or input_action.is_empty():
		return
	
	if input_type == INPUT_TYPE.JUST_PRESS:
		if Input.is_action_just_pressed(input_action):
			target.visible = !target.visible

func _process(delta: float) -> void:
	if input_type != INPUT_TYPE.PRESS:
		return
	
	target.visible = Input.is_action_pressed(input_action)

func _ready() -> void:
	if hide_at_start:
		target.hide()
	
	if !target:
		target = get_parent()
	
	if !target.is_node_ready():
		await target.ready
	
	if target.is_visible_in_tree():
		SimusDev.ui.open_interface(self)
	
	target.draw.connect(_on_draw)
	target.hidden.connect(_on_hidden)

func _on_draw() -> void:
	SimusDev.ui.open_interface(self)

func _on_hidden() -> void:
	SimusDev.ui.close_interface(self)
