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
	
	child_exiting_tree.connect(_on_child_exiting_tree)
	child_entered_tree.connect(_on_child_entered_tree)

func _on_child_entered_tree(child: Node) -> void:
	if networked:
		var transform_sync: SimusNetTransform = SimusNetTransform.find_transform(child)
		if !transform_sync:
			transform_sync = SimusNetTransform.new()
			transform_sync.name = "transform"
			transform_sync.node = child
			child.add_child(transform_sync)

func _on_child_exiting_tree(child: Node) -> void:
	pass

func get_level() -> LevelInstance:
	return _level
