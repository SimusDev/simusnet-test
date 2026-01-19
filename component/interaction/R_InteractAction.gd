extends R_Object
class_name R_InteractAction

@export var name: String = ""
const META: StringName = &"interact_actions"

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
	get_from(object).append(self)
	return self

func remove_from(object: Object) -> R_InteractAction:
	get_from(object).erase(self)
	return self
