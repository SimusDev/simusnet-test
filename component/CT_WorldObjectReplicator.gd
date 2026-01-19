extends SimusNetNodeSceneReplicator
class_name CT_WorldObjectReplicator

func serialize_custom(node: Node, data: Dictionary) -> void:
	var w_object: I_WorldObject = I_WorldObject.find_in(node)
	if w_object:
		data.iwo = w_object.serialize()
	

func deserialize_custom(data: Dictionary, node: Node) -> void:
	if data.has("iwo"):
		I_WorldObject.deserialize(data.iwo, node, LevelInstance.find_above(self))
	
