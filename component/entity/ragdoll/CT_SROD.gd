class_name CT_SROD extends Node #Spawn Ragdoll On Death

@export var entity:Entity
@export var health:CT_Health

func _ready() -> void:
	health.on_value_changed.connect(_on_health_value_changed)

func _on_health_value_changed() -> void:
	if not SimusNetConnection.is_server():
		return
	spawn()

func spawn() -> void:
	var ragdoll = (
		I_WorldObject.find_in(entity).get_object() as R_Entity
		).ragdoll
	
	SpawnableObjects.request_spawn(ragdoll, entity.global_position)
