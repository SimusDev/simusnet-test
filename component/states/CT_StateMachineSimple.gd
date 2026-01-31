extends Node
class_name CT_StateMachineSimple

@export var debug: bool = false
@export var _states: PackedStringArray

var _state: String = ""
var _state_id: int = -1: set = _set_state_id

var _logger: SD_Logger = SD_Logger.new(self)

signal on_transitioned(from: String, to: String)
signal on_state_enter(to: String)
signal on_state_exit(to: String)

func _ready() -> void:
	SimusNetVars.register(self,
	[
		"_state_id",
		
	], SimusNetVarConfig.new().flag_reliable(Network.CHANNEL_STATES).flag_replication())

func add_state(state: String) -> CT_StateMachineSimple:
	if _states.has(state):
		_logger.debug("failed to add state, cant find: %s", SD_ConsoleCategories.ERROR)
		return self
	
	_states.append(state)
	
	if _state_id == -1:
		_transition(state)
	
	return self

func remove_state(state: String) -> CT_StateMachineSimple:
	if !_states.has(state):
		_logger.debug("failed to remove state, cant find: %s", SD_ConsoleCategories.ERROR)
		return self
	_states.erase(state)
	return self

func get_state_list() -> PackedStringArray:
	return _states

func try_switch(to: String) -> CT_StateMachineSimple:
	if not SimusNet.is_network_authority(self):
		_logger.debug("failed to switch state to %s, you're not the owner." % to, SD_ConsoleCategories.ERROR)
		return self
	
	if !_states.has(to):
		_logger.debug("failed to switch state, cant find: %s" % to, SD_ConsoleCategories.ERROR)
		return self
	
	_transition(to)
	
	return self

func make_cooldown_and_switch_to(time: float, state: String) -> CT_StateMachineSimple:
	_make_cd_and_switch(time, state)
	return self

func _make_cd_and_switch(time: float, state: String) -> void:
	await get_tree().create_timer(time, false).timeout
	try_switch(state)

func _transition(to: String) -> void:
	if get_current_state() == to:
		return
	
	var prev: String = get_current_state()
	on_state_exit.emit(prev)
	_state = to
	_state_id = _states.find(to)
	on_state_enter.emit(get_current_state())
	
	on_transitioned.emit(prev, get_current_state())
	if debug:
		_logger.debug("transitioned from %s to %s" % [prev, get_current_state()])

func _set_state_id(new: int) -> void:
	_state_id = new
	if !SimusNet.is_network_authority(self):
		_transition(_states.get(new))

func get_current_state() -> String:
	return _state
