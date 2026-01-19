extends Control
class_name UI_InventoryContainer

@export var inventory: CT_Inventory : set = set_inventory
@export var _container: Control

func set_inventory(new: CT_Inventory) -> void:
	inventory = new
	if !is_node_ready():
		await ready
	
	await _clear()
	if is_instance_valid(inventory):
		_update()

func _clear() -> void:
	await SD_Nodes.async_clear_all_children(_container)

func _update() -> void:
	if !inventory.ready:
		await inventory.on_ready
	
	for slot in inventory.get_slots():
		var ui: UI_InventorySlot = UI_InventorySlot.create(slot)
		_container.add_child(ui)
