@tool
class_name AI_Targeting extends Node

signal target_change

@export var entity_ai:EntityAI

var target:Node3D :
	set(val):
		target = val
		target_change.emit()

func _ready() -> void:
	if not entity_ai:
		return
	
	if not entity_ai.ct_tick:
		return
	
	entity_ai.ct_tick.tick.connect(pick_target)

func _auto_update() -> void:
	if not entity_ai:
		var parent = get_parent()
		if parent is EntityAI:
			entity_ai = parent

func _notification(what):
	match what:
		NOTIFICATION_PARENTED:
			_auto_update()

func _get_target_priority(t:AI_Visible) -> float:
	var t_distance:float = t.root.global_position.distance_to(entity_ai.root.global_position)
	return t_distance * float(t.ai_priority)


func pick_target() -> void:
	if not entity_ai:
		return
	
	var best_target:AI_Visible = null
	
	for ray:AI_EyeRay in entity_ai.eye_rays:
		if not ray.is_colliding():
			continue
		var collider = ray.get_collider()
		if collider is AI_Visible:
			var eye_target:Node3D = collider
			
			if not best_target:
				best_target = eye_target
				continue
			
			if  _get_target_priority(eye_target) > _get_target_priority(best_target):
				best_target = eye_target
	
	target = best_target
