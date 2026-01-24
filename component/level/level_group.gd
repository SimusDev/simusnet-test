extends Node3D
class_name LevelGroup

var _level: LevelInstance

var networked: bool = false

var _replicator: CT_WorldObjectReplicator

func get_replicator() -> CT_WorldObjectReplicator:
	return _replicator

func _ready() -> void:
	_level = LevelInstance.find_above(self)
	
	if networked:
		_replicator = CT_WorldObjectReplicator.new()
		_replicator.name = "replicator"
		_replicator.root = self
		add_child(_replicator)
	
	child_exiting_tree.connect(_on_child_exiting_tree)
	child_entered_tree.connect(_on_child_entered_tree)

func _on_child_entered_tree(child: Node) -> void:
	if !child.is_node_ready():
		await child.ready
	
	var world_object: I_WorldObject = I_WorldObject.find_in(child)
	if world_object:
		if world_object.get_object():
			world_object.get_object()._spawned(child, self)
	
	if networked:
		var transform_sync: SimusNetTransform = SimusNetTransform.find_transform(child)
		if !transform_sync:
			transform_sync = SimusNetTransform.new()
			transform_sync.name = "transform"
			transform_sync.node = child
			transform_sync.set_multiplayer_authority(child.get_multiplayer_authority())
			child.add_child(transform_sync)

func async_clear_all_children() -> void:
	for i in get_children():
		if i is SimusNetNodeSceneReplicator:
			continue
		i.queue_free()
		await i.tree_exited
	

func _on_child_exiting_tree(child: Node) -> void:
	pass

func get_level() -> LevelInstance:
	return _level
