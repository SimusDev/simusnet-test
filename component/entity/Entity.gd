class_name Entity extends CharacterBody3D

func find_collisions_above() -> Array[CollisionObject3D]:
	var bodies: Array[CollisionObject3D] = []
	
	var children = find_children("*", "CollisionObject3D", true, false)
	for child in children:
		if child is CollisionObject3D:
			bodies.append(child)
	return bodies

func find_collisions_rids_above() -> Array[RID]:
	var rids:Array[RID]
	for collision in find_collisions_above():
		rids.append(collision.get_rid())
	return rids
