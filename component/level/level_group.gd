extends Node3D
class_name LevelGroup

var _level: LevelInstance

var networked: bool = false

var _replicator: SimusNetNodeSceneReplicator

func _ready() -> void:
	_level = LevelInstance.find_above(self)
	
	if networked:
		_replicator = SimusNetNodeSceneReplicator.new()
		_replicator.name = "replicator"
		_replicator.root = self
		add_child(_replicator)

func get_level() -> LevelInstance:
	return _level
