class_name CT_Placeable extends Node

@export var placeable:R_PlaceableSettings

@export_group("Custom Settings")
@export var custom_item:W_Item

var item:W_Item

func _ready() -> void:
	if custom_item:
		item = custom_item
	else:
		if get_parent() is W_Item:
			item = get_parent()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(item):
		return
	
	var space_state = item.get_world_3d().direct_space_state
	var origin = item.player_camera.global_position
	var target = item.origin - item.player.camera.global_transform.basis.z * placeable.place_range
	
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	
	
	var result = space_state.intersect_ray(query)
	
	if result:
		pass
