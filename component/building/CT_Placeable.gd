class_name CT_Placeable extends Node

@export var placeable:R_PlaceableSettings

@export_group("Custom Settings")
@export var custom_item:W_Item

var item:W_Item

var current_ghost:Node3D = null
var ghost_offset: Vector3 = Vector3.ZERO

@onready var level_instance = LevelInstance.find_above(self)

func _ready() -> void:
	if not get_parent().is_node_ready():
		await get_parent().ready
		
	
	if custom_item:
		item = custom_item
	else:
		if get_parent() is W_Item:
			item = get_parent()
	
	if not is_instance_valid(item):
		return
	
	if item.inventory.is_local():
		set_process( SimusNet.is_network_authority(self) )
		set_process_input( SimusNet.is_network_authority(self) )
		set_physics_process( SimusNet.is_network_authority(self) )
	
	if placeable:
		if not placeable.object:
			placeable.object = item.object
	
	item.on_server_use_pressed.connect(_place)
	
	_spawn_ghost()


func _place() -> void:
	if not SimusNetConnection.is_server():
		return
	if not is_inside_tree():
		return
	if not is_instance_valid(item):
		return
	if not is_instance_valid(current_ghost):
		return
	
	var transform:Transform3D = current_ghost.transform
	var new_object:Node = (I_WorldObject.new(level_instance, placeable.object)
							.instantiate()
							.get_instance()
							)
	new_object.transform = transform
	#item.stack.quantity -= 1 #if survival ))

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(current_ghost) or not is_instance_valid(item):
		return

	var eyes = item.entity_head.get_eyes()
	var space_state = item.get_world_3d().direct_space_state
	
	var origin = eyes.global_position
	var target = origin - eyes.global_transform.basis.z * placeable.place_range
	
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	query.collide_with_areas = true
	
	query.exclude = [item.entity_head.get_entity()]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		if result.collider is CT_BuildSnapPoint:
			current_ghost.global_position = result.collider.global_position
		else:
			current_ghost.global_position = result.position + (result.normal * 0.001) - (current_ghost.global_transform.basis * ghost_offset)
	else:
		current_ghost.global_position = target


func _delete_ghost() -> void:
	if is_instance_valid(current_ghost):
		current_ghost.queue_free()
	current_ghost = null

func _spawn_ghost() -> void:
	_delete_ghost()
	if not is_placeable_valid(): return

	var model = placeable.get_model()
	if model is Mesh:
		current_ghost = MeshInstance3D.new()
		current_ghost.mesh = model
	elif model is PackedScene:
		current_ghost = model.instantiate()
	
	if not current_ghost: return
	
	add_child(current_ghost)
	_setup_ghost_visuals(current_ghost)
	_calculate_ghost_offset()

func _setup_ghost_visuals(node: Node) -> void:
	var mat = placeable.shader_material.duplicate()
	current_ghost.set("material_override", mat)
	for child in node.find_children("*", "GeometryInstance3D", true, false):
		child.set("material_override", mat)
		child.set("cast_shadow", GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

func _calculate_ghost_offset() -> void:
	var total_aabb: AABB
	var first = true
	
	var geometries = current_ghost.find_children("*", "GeometryInstance3D", true, false)
	if current_ghost is GeometryInstance3D: geometries.push_back(current_ghost)

	for geo in geometries:
		var local_aabb = geo.get_aabb()
		var rel_tf = current_ghost.global_transform.affine_inverse() * geo.global_transform
		if first:
			total_aabb = rel_tf * local_aabb
			first = false
		else:
			total_aabb = total_aabb.merge(rel_tf * local_aabb)
	
	if not first:
		ghost_offset = Vector3(total_aabb.get_center().x, total_aabb.position.y, total_aabb.get_center().z)


func is_placeable_valid() -> bool:
	return bool(placeable and placeable.object)


func is_valid_mesh(node:Node3D) -> bool:
	return node is MeshInstance3D or node is CSGPrimitive3D
