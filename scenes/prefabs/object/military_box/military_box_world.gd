extends RigidBody3D

@onready var ct_chest: CT_Chest = $CT_Chest

var inv: CT_Inventory
const COAL = preload("uid://ce1e2a4kac0ar")

func _ready() -> void:
	if not ct_chest.is_node_ready():
		await ct_chest.ready
	while not inv:
		inv = CT_Inventory.find_in(self)
		if not inv:
			await get_tree().create_timer(0.1).timeout
		
	for x in range(0, inv.get_slots().size() - 1):
		inv.try_add_item( CT_ItemStack.create_from_object(COAL) )
