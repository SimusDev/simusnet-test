extends SimusNetNodeSceneReplicator
class_name CT_WorldObjectReplicator

func serialize_custom(node: Node, data: Dictionary) -> void:
	var w_object: I_WorldObject = I_WorldObject.find_in(node)
	if w_object:
		data.iwo = w_object.serialize()
	
	var user: CT_User = CT_User.find_in(node)
	if user:
		data.u = user.serialize_reference()
	
	var meta_global: Dictionary = {}
	_serialize_meta_recursive(meta_global, node, node)
	if !meta_global.is_empty():
		data.meta = SimusNetCompressor.parse(meta_global)


func _serialize_meta_recursive(global: Dictionary, node: Node, _root: Node) -> void:
	if node.has_method("_object_replicator_serialize_meta"):
		var meta: Dictionary = global.get_or_add(_root.get_path_to(node), {})
		node._object_replicator_serialize_meta(meta)
	
	for i in node.get_children():
		_serialize_meta_recursive(global, i, _root)

func _deserialize_meta_recursive(global_bytes: PackedByteArray, _root: Node) -> void:
	var global: Dictionary = SimusNetDecompressor.parse(global_bytes)
	for path: NodePath in global:
		var node: Node = _root.get_node(path)
		if !node:
			continue
		
		if node.has_method("_object_replicator_deserialize_meta"):
			var meta: Dictionary = global[path]
			node._object_replicator_deserialize_meta(meta)

func deserialize_custom(data: Dictionary, node: Node) -> void:
	if data.has("iwo"):
		I_WorldObject.deserialize(data.iwo, node, LevelInstance.find_above(self))
	if data.has("u"):
		var user: CT_User = CT_User.deserialize_reference(data.u)
		if user:
			user.set_in(node)
	
	if data.has("meta"):
		_deserialize_meta_recursive(data.meta, node)
