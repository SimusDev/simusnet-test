class_name Entity extends CharacterBody3D

func find_physics_bodies_above() -> Array[PhysicsBody3D]:
	var bodies: Array[PhysicsBody3D] = []
	
	var children = find_children("*", "PhysicsBody3D", true, false)
	for child in children:
		if child is PhysicsBody3D:
			bodies.append(child)
	return bodies
