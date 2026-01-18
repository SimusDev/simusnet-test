extends SimusNetNode
class_name CT_Inventory

@export var node: Node
@export var initial_slot_count: int = 16

var _item_stacks: Array[CT_ItemStack]
var _slots: Array[CT_InventorySlot]

signal on_synchronized()
signal on_ready()

var is_ready: bool = false

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
		is_ready = true
		on_ready.emit()
		return
	
	SimusNetRPC.invoke_on_server(_send)
	

func _network_setup() -> void:
	SimusNetNodeAutoVisible.register_or_get(self)
	
	SimusNetRPC.register(
		[
			_send,
			_try_move_item_server,
		], SimusNetRPCConfig.new().flag_mode_any_peer().
		flag_set_channel(Network.CHANNEL_INVENTORY).flag_serialization()
	)
	
	SimusNetRPC.register(
		[
			_receive,
			_receive_item_add,
			_receive_item_remove,
			
		], SimusNetRPCConfig.new().flag_mode_server_only().
		flag_set_channel(Network.CHANNEL_INVENTORY).flag_serialization()
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
	var free_slot: CT_InventorySlot = get_free_slot()
	if !free_slot:
		item.queue_free()
		return null
	
	return new
	
func try_remove_item(item: CT_ItemStack) -> void:
	if !SimusNetConnection.is_server():
		return
	
	if _item_stacks.has(item):
		item.queue_free()

func try_move_item(item: CT_ItemStack, slot: CT_InventorySlot) -> void:
	if _item_stacks.has(item):
		SimusNetRPC.invoke_on_server(_try_move_item_server, item, slot)

func _try_move_item_server(item: CT_ItemStack, slot: CT_InventorySlot) -> void:
	if !is_instance_valid(slot):
		return
	
	if SimusNet.get_network_authority(slot.get_inventory()) == SimusNetRemote.sender_id:
		if _item_stacks.has(item):
			if slot.can_move_item(item):
				item.reparent(slot)

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
	
	is_ready = true
	on_ready.emit()
	

func _on_item_added(slot: CT_InventorySlot, item: CT_ItemStack) -> void:
	if !SimusNetConnection.is_server():
		return
	
	await get_tree().process_frame
	SimusNetRPC.invoke(_receive_item_add, slot, item.serialize())

func _on_item_removed(slot: CT_InventorySlot, item: CT_ItemStack) -> void:
	if !SimusNetConnection.is_server():
		return
	
	await get_tree().process_frame
	SimusNetRPC.invoke(_receive_item_remove, slot)

func _receive_item_add(slot: CT_InventorySlot, item: Variant) -> void:
	if !is_ready:
		return
	
	slot.add_child(CT_ItemStack.deserialize(item))

func _receive_item_remove(slot: CT_InventorySlot) -> void:
	if !is_ready:
		return
	
	if slot.get_item_stack():
		slot.get_item_stack().queue_free()
