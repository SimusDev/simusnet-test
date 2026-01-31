extends R_SpawnTag
class_name R_SpawnTagFreeze

@export var freeze: bool = true

func init(instance: Node, object: R_WorldObject) -> void:
	super(instance, object)
	if instance is RigidBody3D:
		instance.freeze = freeze
