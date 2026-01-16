@tool
extends Node
class_name A_ItemAnimation

@export var animator: CT_ItemAnimator

@export var hook: R_AnimationHook

func _ready() -> void:
	if get_parent() is CT_ItemAnimator:
		animator = get_parent()
	
