extends Node3D

var _scale: float = 1.0
var _strength: float = 1.0

const LIFE_TIME: float = 1.0
const PARTICLES: PackedScene = preload("res://component/entity/W_ExplosionParticles.tscn")

func _ready() -> void:
	await get_tree().process_frame
	
	if SimusNetConnection.is_client():
		var particles: Node3D = PARTICLES.instantiate()
		particles.explosion = self
		LevelInstance.find_above(self).add_child(particles)
		particles.global_position = global_position
	
	await get_tree().create_timer(LIFE_TIME).timeout
	queue_free()

func _object_replicator_serialize_meta(meta: Dictionary) -> void:
	meta[0] = _scale
	meta[1] = _strength

func _object_replicator_deserialize_meta(meta: Dictionary) -> void:
	_scale = meta[0]
	_strength = meta[1]
