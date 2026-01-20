extends Node
class_name CT_NodeInteractions

@export var target: Node
@export var list: Array[R_InteractAction] = []

func _ready() -> void:
	if !target:
		target = get_parent()
	
	if target is CollisionObject3D:
		CT_Collisions.set_body_collision(target, CT_Collisions.LAYERS.INTERACTION, true, true)
	
	for i in list:
		i.append_to(target)
