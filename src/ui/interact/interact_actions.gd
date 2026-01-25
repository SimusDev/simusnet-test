@tool
extends Control
class_name UI_InteractActions

@onready var _panel: Panel = $Panel
@onready var _v_box_container: VBoxContainer = $VBoxContainer

@export var _action_scene: PackedScene

const SCENE: PackedScene = preload("uid://dupat60mhflep")

signal on_selected(action: R_InteractAction)

enum MODE {
	INTERACTION,
	UI,
}

var _mode: MODE = MODE.UI

func set_mode(mode: MODE) -> UI_InteractActions:
	_mode = mode
	
	set_process_input(_mode == MODE.INTERACTION)
	
	return self

func _ready() -> void:
	hide()
	
	if Engine.is_editor_hint():
		return
	
	set_mode(_mode)
	
	SD_Nodes.clear_all_children(_v_box_container)

var _selected_action: int = 0
func get_actions_size() -> int:
	return _v_box_container.get_child_count()

func _input(event: InputEvent) -> void:
	if SimusDev.ui.has_active_interface():
		return
	
	if !is_visible_in_tree():
		return
	
	if Input.is_action_just_released("scroll_up"):
		_selected_action += 1
		update()
	
	#if Input.is_action_just_pressed("scroll_down"):
		#_selected_action += 1
		#update()
	
	if Input.is_action_just_pressed("interact"):
		if get_actions_size() > 0:
			on_selected.emit(_v_box_container.get_child(_selected_action).action)
		else:
			on_selected.emit(null)
	

func update() -> void:
	if _mode == MODE.INTERACTION:
		if _selected_action < 0:
			_selected_action = get_actions_size() - 1
		
		if _selected_action > get_actions_size() - 1:
			_selected_action = 0
		
		#print(_selected_action)
		
		for action in _v_box_container.get_children():
			action.set_selected(action.get_index() == _selected_action)
		

func _process(delta: float) -> void:
	_panel.size = _v_box_container.size
	_panel.position = _v_box_container.position

func set_actions(actions: Array[R_InteractAction]) -> UI_InteractActions:
	SD_Nodes.clear_all_children(_v_box_container)
	if !actions.is_empty():
		for action in actions:
			var ui: Node = _action_scene.instantiate()
			ui.action = action
			_v_box_container.add_child(ui)
		_selected_action = 0
		update()
	return self

static func create() -> UI_InteractActions:
	return SCENE.instantiate()
