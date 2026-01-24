class_name CT_Placeable extends Node

@export var placeable:R_PlaceableSettings

@export_group("Custom Settings")
@export var custom_item:W_Item

var item:W_Item

var current_ghost:Node3D = null

func _ready() -> void:
	if not get_parent().is_node_ready():
		await get_parent().ready
	
	set_process( SimusNet.is_network_authority(self) )
	set_process_input( SimusNet.is_network_authority(self) )
	set_physics_process( SimusNet.is_network_authority(self) )
	
	if custom_item:
		item = custom_item
	else:
		if get_parent() is W_Item:
			item = get_parent()
	
	if is_instance_valid(item) and placeable:
		if not placeable.object:
			placeable.object = item.object
	
	_spawn_ghost()

func _physics_process(_delta: float) -> void:
	if not is_inside_tree():
		return
	if not is_instance_valid(item) || not is_instance_valid(current_ghost):
		return
	if is_instance_valid(item.player_camera):
		var space_state = item.get_world_3d().direct_space_state
		var origin = item.player_camera.global_position
		var target = item.global_position - item.player_camera.global_transform.basis.z * placeable.place_range
		
		var query = PhysicsRayQueryParameters3D.create(origin, target)
		
		var result = space_state.intersect_ray(query)
		#current_ghost.visible = result
		
		if result:
			current_ghost.global_position = result.position
		else:
			current_ghost.global_position = item.global_position - item.player_camera.global_transform.basis.z * placeable.place_range


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
