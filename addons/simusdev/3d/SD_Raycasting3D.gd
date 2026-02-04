@static_unload
extends RefCounted
class_name SD_Raycasting3D

static func intersect_ray_from_node(node: Node3D, range_multiplier: float = 1.0) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = node.get_world_3d().direct_space_state
	var origin: Vector3 = node.global_position
	var target: Vector3 = origin - node.global_transform.basis.z * range_multiplier
	
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, target)
	
	var result: Dictionary = space_state.intersect_ray(query)
	return result
