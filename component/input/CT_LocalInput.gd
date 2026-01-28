extends Node
class_name CT_LocalInput

signal on_input(event: InputEvent)
signal on_unhandled_input(event: InputEvent)

signal on_action_just_pressed(action: StringName)

@export var root: Node

func _ready() -> void:
	if !root:
		root = get_parent()
	
	SD_ECS.append_to(root, self)
	
	if !root.is_node_ready():
		await root.ready
	
	var playable: CT_Playable = SD_ECS.find_first_component_by_script(root, [CT_Playable])
	
	if !is_instance_valid(playable) or !SimusNet.is_network_authority(playable):
		process_mode = Node.PROCESS_MODE_DISABLED

func _input(event: InputEvent) -> void:
	if SimusDev.ui.has_active_interface():
		return
	
	on_input.emit(event)
	
	for action in InputMap.get_actions():
		if Input.is_action_just_pressed(action):
			on_action_just_pressed.emit(action)

func _unhandled_input(event: InputEvent) -> void:
	if SimusDev.ui.has_active_interface():
		return
	
	on_unhandled_input.emit(event)

static func get_or_create(entity: Node3D) -> CT_LocalInput:
	var input: CT_LocalInput = SD_ECS.find_first_component_by_script(entity, [CT_LocalInput])
	if is_instance_valid(input):
		return input
	
	input = CT_LocalInput.new()
	input.root = entity
	input.set_multiplayer_authority(entity.get_multiplayer_authority())
	input.name = "LocalInput"
	_async_create(entity, input)
	return input

static func _async_create(entity: Node3D, input: CT_LocalInput) -> void:
	if !entity.is_node_ready():
		await entity.ready
	entity.add_child(input)
