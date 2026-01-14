extends SimusNetNode
class_name CT_Inventory

@export var node: Node
@export var initial_slot_count: int = 16

var _item_stacks: Array[CT_ItemStack]
var _slots: Array[CT_InventorySlot]

signal on_synchronized()

func get_item_stacks() -> Array[CT_ItemStack]:
	return _item_stacks

func get_slot_script() -> GDScript:
	return CT_InventorySlot

func get_slots() -> Array[CT_InventorySlot]:
	return _slots

func get_slots_by_script(script: GDScript) -> Array[CT_InventorySlot]:
	var result: Array[CT_InventorySlot] = []
	for slot in get_slots():
		if slot.get_script() == script:
			result.append(slot)
	return result

func _ready() -> void:
	_network_setup()
	super()
	
	if !node:
		node = get_parent()
	
	SD_ECS.append_to(node, self)
	
	if SimusNetConnection.is_server():
		for id: int in initial_slot_count:
			var slot: CT_InventorySlot = CT_InventorySlot.new()
			slot.name = "i_%s" % id
			add_child(slot)

static func find_in(node: Node) -> CT_Inventory:
	return SD_ECS.find_first_component_by_script(node, [CT_Inventory])

func _network_ready() -> void:
	super()
	synchronize()

func synchronize() -> void:
	if SimusNetConnection.is_server():
		return
	
	SimusNetRPC.invoke_on_server(_send)

func _network_setup() -> void:
	SimusNetNodeAutoVisible.register_or_get(self)
	
	SimusNetRPC.register(
		[
			_send,
		], SimusNetRPCConfig.new().flag_mode_any_peer().flag_set_channel(Network.CHANNEL_INVENTORY)
	)
	
	SimusNetRPC.register(
		[
			_receive,
			_try_add_item_rpc,
			
		], SimusNetRPCConfig.new().flag_mode_server_only().flag_set_channel(Network.CHANNEL_INVENTORY)
	)
	

func get_free_slot() -> CT_InventorySlot:
	for i in get_slots():
		if i.is_free():
			return i
	return null

func try_add_item(item: CT_ItemStack) -> CT_ItemStack:
	if !item.get_inventory():
		item.queue_free()
	
	if !SimusNetConnection.is_server():
		return null
	
	var new: CT_ItemStack = item.duplicate()
	_try_add_item_server(new)
	return new
	

func _try_add_item_server(item: CT_ItemStack) -> void:
	await get_tree().process_frame
	var free_slot: CT_InventorySlot = get_free_slot()
	if !free_slot:
		item.queue_free()
		return 
	
	SimusNetRPC.invoke_all(_try_add_item_rpc, item.serialize(), free_slot.get_id())

func _try_add_item_rpc(serialized: Variant, slot_id: int) -> void:
	var slot: CT_InventorySlot = CT_InventorySlot.get_by_id(self, slot_id)
	var item: CT_ItemStack = CT_ItemStack.deserialize(serialized)
	slot.add_child(item)

func try_remove_item(item: CT_ItemStack) -> void:
	if !SimusNetConnection.is_server():
		return
	
	if _item_stacks.has(item):
		item.remove()
	
	

func _send() -> void:
	var bytes: PackedByteArray = CT_InventorySlot.serialize_array(get_slots())
	SimusNetRPC.invoke_on(SimusNetRemote.sender_id, _receive, bytes)

func _receive(raw: PackedByteArray) -> void:
	for i in get_children():
		if i is CT_InventorySlot:
			i.queue_free()
			await i.tree_exited
	
	var slots: Array[CT_InventorySlot] = CT_InventorySlot.deserialize_array(raw)
	for i in slots:
		add_child(i)
