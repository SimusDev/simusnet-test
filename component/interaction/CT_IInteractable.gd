extends Node
class_name CT_IInteractable

@export var target: Node

signal on_server_interacted_by_ray(ray: CT_InteractionRay)
signal on_local_interacted_by_ray(ray: CT_InteractionRay)

signal on_server_player_interacted_by_ray(playable: CT_Playable, ray: CT_InteractionRay)
signal on_local_player_interacted_by_ray(playable: CT_Playable, ray: CT_InteractionRay)

func _ready() -> void:
	if !target:
		target = get_parent()
	
	CT_Collisions.set_body_collision(target, CT_Collisions.LAYERS.INTERACTION)
	
	SD_ECS.append_to_anyway(target, self)
