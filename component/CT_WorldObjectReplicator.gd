extends SimusNetNodeSceneReplicator
class_name CT_WorldObjectReplicator

func serialize_custom(node: Node, data: Dictionary) -> void:
	var w_object: I_WorldObject = I_WorldObject.find_in(node)
	if w_object:
		data.iwo = w_object.serialize_network()
	
	var user: CT_User = CT_User.find_in(node)
	if user:
		data.u = user.serialize_reference()
	

func deserialize_custom(data: Dictionary, node: Node) -> void:
	if data.has("iwo"):
		I_WorldObject.deserialize_network(data.iwo, node, LevelInstance.find_above(self))
	if data.has("u"):
		var user: CT_User = CT_User.deserialize_reference(data.u)
		if user:
			user.set_in(node)
