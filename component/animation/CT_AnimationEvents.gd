extends Node
class_name CT_AnimationEvents

@export var target: Node

var _events: Dictionary[String, EVENT] = {}

func _ready() -> void:
	if !target:
		target = get_parent()
	
	SD_ECS.append_to(target, self)

static func async_find_above(from: Node, attempts: int = 1) -> CT_AnimationEvents:
	return await _async_find_above_internal(from, 0, attempts, CT_AnimationEvents)

static func _async_find_above_internal(from: Node, attempts: int, max_attempts: int, script: GDScript) -> CT_AnimationEventsCharacter:
	if !is_instance_valid(from):
		return null
	
	var founded: Node = SD_ECS.node_find_above_by_component(from, script)
	if founded:
		return founded
	
	if attempts > max_attempts:
		return null
	
	attempts += 1
	
	await SimusDev.get_tree().process_frame
	return await _async_find_above_internal(from, attempts, max_attempts, script)

func get_or_create(code: String) -> EVENT:
	var e: EVENT = EVENT.new()
	e.set_code(str(target) + ":" + code)
	return _events.get_or_add(code, e)
