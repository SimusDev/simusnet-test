@tool
class_name AI_Targeting extends Node

signal target_change

var target:Node3D :
	set(val):
		if target != val:
			target = val
			target_change.emit()

static func find_above(node: Node) -> AI_Targeting:
	for c in node.get_children():
		if c is AI_Targeting:
			return c
	
	for c in node.get_children():
		var found = find_above(c)
		if found:
			return found
	
	return null

func _ready() -> void:
	pass

func _get_target_weight(from: Node3D, t: AI_Visible) -> float:
	if not from or not t:
		return INF
	
	var t_distance: float = t.global_position.distance_to(from.global_position)
	return t_distance / float(t.ai_priority)


func pick_target(ai_root: Node3D, eye_rays: Array[AI_EyeRay]) -> void:
	if eye_rays.is_empty():
		target = null # Очищаем цель, если некуда смотреть
		return
	
	var best_target: AI_Visible = null
	var min_weight: float = INF # Ищем минимальный вес
	
	for ray: AI_EyeRay in eye_rays:
		if not ray.is_colliding():
			continue
			
		var collider = ray.get_collider()
		if collider is AI_Visible:
			var current_weight = _get_target_weight(ai_root, collider)
			
			if current_weight < min_weight:
				min_weight = current_weight
				best_target = collider
	
	target = best_target as Node3D
