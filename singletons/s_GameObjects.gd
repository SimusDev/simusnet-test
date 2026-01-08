extends Node

@onready var _logger: SD_Logger = SD_Logger.new(self)

@onready var _handlers: Node = $Handlers

func handler_register(id: StringName) -> CT_ObjectHandler:
	if _handlers.has_node(str(id)):
		return _handlers.get_node(str(id))
	
	var handler: CT_ObjectHandler = CT_ObjectHandler.new()
	handler.name = id
	_handlers.add_child(handler)
	return handler
