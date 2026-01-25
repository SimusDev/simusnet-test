class_name CT_Placeable extends Node

@export var placeable:R_PlaceableSettings

@export_group("Custom Settings")
@export var custom_item:W_Item

var item:W_Item

var current_ghost:Node3D = null

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
	
	item.pressed.connect(_place)
	
	_spawn_ghost()


func _place() -> void:
	if not SimusNetConnection.is_server():
		return
		
	if not is_inside_tree() or not is_instance_valid(item) or not is_instance_valid(current_ghost):
		return
	
	var transform:Transform3D = current_ghost.global_transform
	var new_object:Node = (I_WorldObject.new(level_instance, placeable.object)
							.instantiate()
							.get_instance()
							)
	new_object.global_transform = transform
	print("SPAWN")
	#item.stack.quantity -= 1

func _physics_process(_delta: float) -> void:
	if not is_inside_tree() or not is_instance_valid(item) or not is_instance_valid(current_ghost):
		return
	
	var eyes: Node3D = item.entity_head.get_eyes()
	var space_state = item.get_world_3d().direct_space_state
	
	var origin = eyes.global_position
	var direction = -eyes.global_transform.basis.z
	var target = origin + direction * placeable.place_range
	
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [item.entity_head.get_entity()]
	
	var result = space_state.intersect_ray(query)

	if result:
		var pos = result.position
		
		var normal = result.normal
		
		var offset_dist = 0.05
		var mesh_node = current_ghost.find_children("*", "MeshInstance3D")[0]
		if mesh_node:
			var aabb = mesh_node.get_aabb()
			pos += normal * (aabb.size.y * 0.5)
		else:
			pos += normal * offset_dist
		current_ghost.global_position = pos
		
	else:
		current_ghost.global_position = target

func _delete_ghost() -> void:
	if is_instance_valid(current_ghost):
		current_ghost.queue_free()
	current_ghost = null

func _spawn_ghost() -> void:
	if not is_placeable_valid():
		return
	
	_delete_ghost()
	var model:Variant = placeable.get_model()
	if model is Mesh:
		current_ghost = Node3D.new()
		add_child(current_ghost)
		
		var mesh_inst:MeshInstance3D = MeshInstance3D.new()
		mesh_inst.mesh = model
		
		current_ghost.add_child(mesh_inst)
		_apply_shader_to_meshes()
		return
	
	elif model is PackedScene:
		current_ghost = model.instantiate()
		add_child(current_ghost)
		_apply_shader_to_meshes()

func _apply_shader_to_meshes() -> void:
	if not is_placeable_valid():
		return
	
	var sm = placeable.shader_material.duplicate()
	
	for child in current_ghost.find_children("*", "GeometryInstance3D"):
		child.set("material_override", sm)


func is_placeable_valid() -> bool:
	return bool(placeable and placeable.object)


func is_valid_mesh(node:Node3D) -> bool:
	return node is MeshInstance3D or node is CSGPrimitive3D
