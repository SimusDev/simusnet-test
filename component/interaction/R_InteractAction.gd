extends R_Object
class_name R_InteractAction

@export var name: String = ""
const META: StringName = &"interact_actions"

static var ACTION_OPEN: R_InteractAction = load("res://src/objects/interact/actions/open.tres")
static var ACTION_PICKUP: R_InteractAction = load("res://src/objects/interact/actions/pickup.tres") 
static var ACTION_USE: R_InteractAction = load("res://src/objects/interact/actions/use.tres") 

static func get_group() -> String:
	return "interact_action"

func _server_selected_world(object: Node3D, raycast: CT_InteractionRay) -> void:
	pass

func _server_selected_itemstack(item: CT_ItemStack) -> void:
	pass

#func _local_selected_world(object: Node3D, raycast: CT_InteractionRay) -> void:
	#pass
#
#func _local_selected_itemstack(item: CT_ItemStack) -> void:
	#pass

static func get_from(object: Object) -> Array[R_InteractAction]:
	return SD_Variables.get_or_add_object_meta(object, META, [] as Array[R_InteractAction])

func append_to(object: Object) -> R_InteractAction:
	if object is CollisionObject3D:
		CT_Collisions.set_body_collision(object, CT_Collisions.LAYERS.INTERACTION, true, false)
	
	get_from(object).append(self)
	return self

func remove_from(object: Object) -> R_InteractAction:
	get_from(object).erase(self)
	return self
