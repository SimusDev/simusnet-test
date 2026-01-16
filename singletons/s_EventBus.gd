extends Node

var _registry: Dictionary[String, EVENT] = {}

@onready var _logger: SD_Logger = SD_Logger.new(self)

func _ready() -> void:
	pass

func subscribe(event_id: String, callable: Callable) -> void:
	var founded: EVENT = _registry.get(event_id)
	if !founded:
		_logger.debug("subscribe(), cant find event by %s ID" % [event_id])
		return
	
	founded.published.connect(callable.bind(founded))

func subscribe_pre(event_id: String, callable: Callable) -> void:
	var founded: EVENT = _registry.get(event_id)
	if !founded:
		_logger.debug("subscribe_pre(), cant find event by %s ID" % [event_id])
		return
	
	founded.published_pre.connect(callable.bind(founded))

func subscribe_post(event_id: String, callable: Callable) -> void:
	var founded: EVENT = _registry.get(event_id)
	if !founded:
		_logger.debug("subscribe_post(), cant find event by %s ID" % [event_id])
		return
	
	founded.published_post.connect(callable.bind(founded))

func get_event(id: String) -> EVENT:
	return _registry.get(id)

func register_event(event: EVENT, id: String) -> EVENT:
	if _registry.has(id):
		return _registry[id]
	
	_registry[id] = event
	return event

func unregister_event(id: String) -> EVENT:
	var founded: EVENT = _registry.get(id)
	_registry.erase(id)
	return founded
