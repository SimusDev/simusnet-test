extends Node
class_name UI_SlotControl

@export var inventory: CT_Inventory : set = set_inventory
@export var _container: Control

@export var _slots_scripts: Array[GDScript] = []
@export var use_default_script: bool = true
@export var _slot_tags: Dictionary[String, Variant] = {}

func set_inventory(new: CT_Inventory) -> void:
	inventory = new
	
	if use_default_script and !_slots_scripts.has(CT_InventorySlot):
		_slots_scripts.append(CT_InventorySlot)
	
	if !is_node_ready():
		await ready
	
	await _clear()
	if is_instance_valid(inventory):
		_update()

func _clear() -> void:
	if !_container:
		return
	
	await SD_Nodes.async_clear_all_children(_container)

func _update() -> void:
	if !inventory.is_ready:
		await inventory.on_ready
	
	for script in _slots_scripts:
		for slot in inventory.get_slots_by_script(script):
			if _slot_tags == slot.tags:
				var ui: UI_InventorySlot = UI_InventorySlot.create(slot)
				_container.add_child(ui)
