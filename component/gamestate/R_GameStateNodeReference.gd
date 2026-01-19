extends Resource
class_name R_GameStateNodeReference

var instance: Node = null

var _listeners_save: Array[Callable] = []
var _listeners_load: Array[Callable] = []

static var _references: Array[R_GameStateNodeReference] = []

func _on_save() -> void:
	if !is_instance_valid(instance):
		_references.erase(self)
		return
	
	var ref: R_GameStateNodeInstance = s_GameState._register_instance(instance)
	
	for i in _listeners_save:
		if !i.is_null():
			i.call(ref)

func _on_load() -> void:
	if !is_instance_valid(instance):
		_references.erase(self)
		return
	
	var ref: R_GameStateNodeInstance = s_GameState._register_instance(instance)
	if ref.is_data_empty():
		return
	
	for i in _listeners_load:
		if !i.is_null():
			i.call(ref)

func on_save_event(callable: Callable) -> R_GameStateNodeReference:
	if !SimusNetConnection.is_server():
		return self
	
	if !_listeners_save.has(callable):
		_listeners_save.append(callable)
	s_GameState.on_begin_save.connect(_on_save)
	#_on_save()
	return self

func on_load_event(callable: Callable) -> R_GameStateNodeReference:
	if !SimusNetConnection.is_server():
		return self
	
	if !_listeners_load.has(callable):
		_listeners_load.append(callable)
	s_GameState.on_load.connect(_on_load)
	_on_load()
	return self

func connect_events(save: Callable, load: Callable) -> R_GameStateNodeReference:
	on_save_event(save)
	on_load_event(load)
	return self

func _init(node: Node) -> void:
	instance = node
	_references.append(self)
	
