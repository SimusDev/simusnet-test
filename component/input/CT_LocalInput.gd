extends Node
class_name CT_LocalInput

signal on_input(event: InputEvent)
signal on_unhandled_input(event: InputEvent)

signal on_action_just_pressed(action: StringName)

func _ready() -> void:
	if !SimusNet.is_network_authority(self):
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
	input.set_multiplayer_authority(entity.get_multiplayer_authority())
	input.name = "LocalInput"
	SD_ECS.append_to(entity, input)
	_async_create(entity, input)
	return input

static func _async_create(entity: Node3D, input: CT_LocalInput) -> void:
	if !entity.is_node_ready():
		await entity.ready
	entity.add_child(input)
