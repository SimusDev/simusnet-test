extends R_Object
class_name R_InteractAction

@export var name: String = ""
const META: StringName = &"interact_actions"

static var ACTION_OPEN: Resource = preload("uid://xecviu4tcm2e") 
static var ACTION_PICKUP: Resource = preload("uid://cvbrrn0mme4i") 
static var ACTION_USE: Resource = preload("uid://cd72i7612o4ut") 

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
		CT_Collisions.set_body_collision(object, CT_Collisions.LAYERS.INTERACTION)
	
	get_from(object).append(self)
	return self

func remove_from(object: Object) -> R_InteractAction:
	get_from(object).erase(self)
	return self
