extends Control
class_name UI_BackpackCustom

var inventory: CT_Inventory : set = set_inventory
var _player_inventory: CT_Inventory

var _interface: Node = null

func get_player_inventory() -> CT_Inventory:
	return _player_inventory

func get_inventory() -> CT_Inventory:
	return inventory

func set_inventory(new: CT_Inventory) -> void:
	inventory = new
	
	if !is_node_ready():
		await ready
	
	if is_instance_valid(_interface):
		_interface.queue_free()
		await _interface.tree_exited
	
	if !is_instance_valid(inventory):
		return
	
	if inventory.backpack_interface:
		_interface = inventory.backpack_interface.instantiate()
		add_child(_interface)

static func find_above(from: Node) -> UI_BackpackCustom:
	return SD_ECS.node_find_above_by_script(from, UI_BackpackCustom)
