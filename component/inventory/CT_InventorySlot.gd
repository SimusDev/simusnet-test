extends Node
class_name CT_InventorySlot

var _item_stack: CT_ItemStack

var _inventory: CT_Inventory

func get_inventory() -> CT_Inventory:
	return _inventory

func get_item_stack() -> CT_ItemStack:
	return _item_stack

func _enter_tree() -> void:
	_inventory = SD_ECS.node_find_above_by_script(self, CT_Inventory)
	_inventory._slots.append(self)

func _exit_tree() -> void:
	_inventory._slots.erase(self)

func serialize() -> Dictionary:
	var data: Dictionary = {}
	if get_script().get_global_name() != "CT_InventorySlot":
		data[0] = SimusNetSerializer.parse_resource(get_script())
	data[1] = name
	
	if get_item_stack():
		data[2] = get_item_stack().serialize()
	return data

static func deserialize(data: Dictionary) -> CT_InventorySlot:
	var script: GDScript = data.get(0, CT_InventorySlot)
	var slot: CT_InventorySlot = script.new()
	slot.name = data[1]
	
	var item_data: Variant = data.get(2, null)
	if item_data:
		var item: CT_ItemStack = CT_ItemStack.deserialize(item_data)
		slot.add_child(item)
	
	return slot

static func serialize_array(array: Array[CT_InventorySlot]) -> PackedByteArray:
	var result: Array = []
	for i in array:
		result.append(i.serialize())
	return SD_Variables.compress(result)

static func deserialize_array(bytes: PackedByteArray) -> Array[CT_InventorySlot]:
	var result: Array[CT_InventorySlot] = []
	for i in SD_Variables.decompress(bytes):
		result.append(deserialize(i))
	return result
