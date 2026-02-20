extends Node

@onready var _logger: SD_Logger = SD_Logger.new(self)

@onready var _data: R_LocalData = R_LocalData.get_or_create("input", "keys")

var _defaults: Dictionary[StringName, Array] = {}

signal on_action_changed(action: StringName)
signal on_action_bind(action: StringName)
signal on_action_reset(action: StringName)

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	
	var binds: Dictionary = _data.get_value_or_add("binds", {})
	
	for action: StringName in get_actions():
		var defualt_events: Array[InputEvent] = InputMap.action_get_events(action).duplicate()
		_defaults[action] = defualt_events
		
		var events: Array[InputEvent] = binds.get_or_add(action, InputMap.action_get_events(action))
		
		InputMap.action_erase_events(action)
		
		for event in events:
			InputMap.action_add_event(action, event)
	
	for action: StringName in binds:
		if !InputMap.has_action(action):
			binds.erase(action)
	
	_data.save()

func get_actions() -> Array[StringName]:
	var result: Array[StringName] = []
	for action in InputMap.get_actions():
		if action.begins_with("ui_"):
			continue
		result.append(action)
	return result

func get_actions_events(action: StringName) -> Array[InputEvent]:
	if !has_action(action):
		_logger.debug("bind_action(), cant find action by StringName: %s" % action)
		return [] as Array[InputEvent]
	return InputMap.action_get_events(action)

func has_action(action: StringName) -> bool:
	return get_actions().has(action)

func bind_action(action: StringName, events: Array[InputEvent]) -> void:
	if !has_action(action):
		_logger.debug("bind_action(), cant find action by StringName: %s" % action)
		return
	
	InputMap.action_erase_events(action)
	
	for event: InputEvent in events:
		InputMap.action_add_event(action, event)
	
	on_action_bind.emit(action)
	on_action_changed.emit(action)
	
	var binds: Dictionary = _data.get_value_or_add("binds", {})
	binds.set(action, get_actions_events(action))
	_data.save()

func reset_action(action: StringName) -> void:
	if !has_action(action):
		_logger.debug("reset_action(), cant find action by StringName: %s" % action)
		return
	
	InputMap.action_erase_events(action)
	
	for event: InputEvent in _defaults[action]:
		InputMap.action_add_event(action, event)
	
	on_action_reset.emit(action)
	on_action_changed.emit(action)
	
	var binds: Dictionary = _data.get_value_or_add("binds", {})
	binds.set(action, get_actions_events(action))
	_data.save()
