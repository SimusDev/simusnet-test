extends HBoxContainer

var _inventory: CT_Inventory

func _ready() -> void:
	_inventory = SD_ECS.find_first_component_by_script(Player.get_local(), [CT_Inventory])
	
	hide()
	await SD_Nodes.async_clear_all_children(self)
	show()
	
	if !_inventory.is_ready:
		await _inventory.on_ready
	
	for slot: CT_InventorySlotHot in _inventory.get_slots_by_script(CT_InventorySlotHot):
		var ui: UI_InventorySlot = load("uid://bu532ooqgmkjg").instantiate()
		ui.slot = slot
		add_child(ui)
	
