class_name AI_Visible extends Area3D

@export var root:Node3D
@export var ai_priority:int = 1

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		if not root:
			root = get_parent()
