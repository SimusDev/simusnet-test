extends Node
class_name CT_InventorySlot

var _item_stack: CT_ItemStack

var _inventory: CT_Inventory

func get_id() -> int:
	return get_index()

static func get_by_id(inventory: CT_Inventory, id: int) -> CT_InventorySlot:
	return inventory.get_child(id)

func is_free() -> bool:
	return !is_instance_valid(_item_stack)

func get_inventory() -> CT_Inventory:
	return _inventory

func get_item_stack() -> CT_ItemStack:
	return _item_stack

func _enter_tree() -> void:
	_inventory = SD_ECS.node_find_above_by_script(self, CT_Inventory)
	SimusNetVisible.set_visibile(self, SimusNetVisible.get_or_create(_inventory))
	_inventory._slots.append(self)

func _exit_tree() -> void:
	_inventory._slots.erase(self)

func serialize() -> Dictionary:
	var data: Dictionary = {}
	if get_script().get_global_name() != "CT_InventorySlot":
		data[0] = SimusNetSerializer.parse_resource(get_script())
	name = name.validate_node_name()
	data[1] = name
	
	if get_item_stack():

		data[2] = get_item_stack().serialize()
	return data


static func deserialize(data: Dictionary) -> CT_InventorySlot:
	var script: GDScript = CT_InventorySlot
	if data.has(0):
		script = SimusNetDeserializer.parse_resource(data.get(0))
	
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
