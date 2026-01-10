extends CT_Entity
class_name CT_EntityLiving

@export var health: CT_Health

func _ready() -> void:
	health = _create_component(health, CT_Health, "health")
	
