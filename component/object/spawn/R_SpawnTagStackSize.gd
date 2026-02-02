extends R_SpawnTag
class_name R_SpawnTagStackSize

@export var quantity: int = 1

func init(instance: Node, object: R_WorldObject) -> void:
	CT_ItemStack.find_or_create_gamestate_stack_reference_in(instance).quantity = quantity
