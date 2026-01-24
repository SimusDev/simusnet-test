extends SimusNetNode
class_name CT_Inventory

@export var node: Node
@export var initial_slot_count: int = 16
@export var backpack_interface: PackedScene

var _playable: CT_Playable

func get_playable() -> CT_Playable:
	return _playable

var _item_stacks: Array[CT_ItemStack]
var _slots: Array[CT_InventorySlot]

var _selected_slot: CT_InventorySlot

signal on_synchronized()
signal on_ready()

signal on_item_added(slot: CT_InventorySlot, item: CT_ItemStack)
signal on_item_removed(slot: CT_InventorySlot, item: CT_ItemStack)

signal on_inventory_closed(inventory: CT_Inventory)
signal on_inventory_opened(inventory: CT_Inventory)

signal on_slot_selected(slot: CT_InventorySlot)
signal on_slot_updated_for_viewmodel(slot: CT_InventorySlot)

var is_ready: bool = false

static var _local: CT_Inventory

func is_local() -> bool:
	return _local == self

static func get_local() -> CT_Inventory:
	if !is_instance_valid(_local):
		_local = null
	return _local

func get_item_stacks() -> Array[CT_ItemStack]:
	return _item_stacks

func get_item_stacks_by_object(object: R_WorldObject) -> Array[CT_ItemStack]:
	var result: Array[CT_ItemStack] = []
	for i in get_item_stacks():
		if i.object == object:
			result.append(i)
	return result

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

func get_slot_by_name(slot_name: String) -> CT_InventorySlot:
	for i in get_slots():
		if i.name == slot_name:
			return i
	return null

func _ready() -> void:
	_network_setup()
	
	if !node:
		node = get_parent()
	
	SD_ECS.append_to(node, self)
	
	if !node.is_node_ready():
		await node.ready
	
	_playable = CT_Playable.find_in(node)
	if _playable:
		if SimusNet.is_network_authority(_playable):
			_local = self
			
	
	if SimusNetConnection.is_server():
		for id: int in initial_slot_count:
			var slot: CT_InventorySlot = CT_InventorySlot.new()
			slot.name = "i_%s" % id
			add_child(slot)
	
	if is_local():
		var hotbar_input: CT_HotbarInput = CT_HotbarInput.new()
		hotbar_input.name = "HotbarInput"
		hotbar_input.set_multiplayer_authority(get_multiplayer_authority())
		hotbar_input.root = node
		hotbar_input.inventory = self
		node.add_child(hotbar_input)
	
	super()

static func find_in(node: Node) -> CT_Inventory:
	return SD_ECS.find_first_component_by_script(node, [CT_Inventory])

func _network_ready() -> void:
	super()
	synchronize()

func synchronize() -> void:
	if SimusNetConnection.is_server():
		_do_network_ready()
		return
	
	SimusNetRPC.invoke_on_server(_send)
	

func _network_setup() -> void:
	SimusNetNodeAutoVisible.register_or_get(self)
	
	SimusNetRPC.register(
		[
			_send,
			_try_move_item_server,
			_request_slot_select_server,
			
		], SimusNetRPCConfig.new().flag_mode_any_peer().
		flag_set_channel(Network.CHANNEL_INVENTORY).flag_serialization()
	)
	
	SimusNetRPC.register(
		[
			_receive,
			_receive_item_add,
			_receive_item_remove,
			_open_server,
			_close_server,
			_request_slot_select_rpc
			
		], SimusNetRPCConfig.new().flag_mode_server_only().
		flag_set_channel(Network.CHANNEL_INVENTORY).flag_serialization()
	)
	
	SimusNetRPC.register(
		[
			open,
			close,
			
		], SimusNetRPCConfig.new().flag_mode_authority().
		flag_set_channel(Network.CHANNEL_INVENTORY).flag_serialization()
	)

func request_slot_select(slot: CT_InventorySlot) -> void:
	if !is_instance_valid(slot):
		return
	
	if slot == get_selected_slot():
		return
	
	if slot is CT_InventorySlotHot:
		SimusNetRPC.invoke_on_server(_request_slot_select_server, slot)
	

func request_slot_select_by_id(id: int) -> void:
	var slots: Array[CT_InventorySlot] = get_slots_by_script(CT_InventorySlotHot)
	var selected: CT_InventorySlot = SD_Array.get_value_from_array(slots, id)
	if selected:
		request_slot_select(selected)
	

func _request_slot_select_server(slot: CT_InventorySlot) -> void:
	if !is_instance_valid(slot):
		return
	
	if slot == get_selected_slot():
		return
	
	if slot is CT_InventorySlotHot:
		SimusNetRPC.invoke_all(_request_slot_select_rpc, slot)

func _request_slot_select_rpc(slot: CT_InventorySlotHot) -> void:
	_selected_slot = slot
	on_slot_selected.emit(slot)
	on_slot_updated_for_viewmodel.emit(slot)

func get_selected_slot() -> CT_InventorySlotHot:
	if !is_instance_valid(_selected_slot):
		_selected_slot = null
	return _selected_slot

func try_pickup(object: Variant) -> bool:
	var stack: CT_ItemStack = null
	
	if object is CT_ItemStack:
		stack = object
		object.queue_free()
	
	if !stack:
		var world_object: I_WorldObject = I_WorldObject.find_in(object)
		if not world_object:
			return false
	
		stack = CT_ItemStack.create_from_object_instance(world_object)
	
	if get_free_slot_for(stack) != null:
		try_add_item(stack)
		object.queue_free()
		stack.queue_free()
		return true
	
	stack.queue_free()
	return false

func get_free_slot_for(item: CT_ItemStack) -> CT_InventorySlot:
	for i in get_slots():
		if i.is_free() and i.can_handle_item(item):
			return i
	return null

func try_add_item(item: CT_ItemStack) -> CT_ItemStack:
	if !item.get_inventory():
		item.queue_free()
	
	if !SimusNetConnection.is_server():
		return null
	
	var new: CT_ItemStack = item.duplicate()
	var free_slot: CT_InventorySlot = get_free_slot_for(new)
	if !free_slot:
		item.queue_free()
		return null
	
	free_slot.add_child(new)
	
	return new
	
func try_remove_item(item: CT_ItemStack) -> void:
	if !SimusNetConnection.is_server():
		return
	
	if _item_stacks.has(item):
		item.queue_free()

func try_move_item(item: CT_ItemStack, slot: CT_InventorySlot) -> void:
	if !is_instance_valid(item) or !is_instance_valid(slot):
		return
	
	var is_inventory_authority: bool = SimusNet.is_network_authority(slot.get_inventory())
	var is_inventory_opened: bool = get_opened().has(slot.get_inventory())
	
	if is_inventory_authority or is_inventory_opened:
		if slot.is_free():
			SimusNetRPC.invoke_on_server(_try_move_item_server, item, slot)

func _try_move_item_server(item: CT_ItemStack, slot: CT_InventorySlot) -> void:
	if !is_instance_valid(slot) or !is_instance_valid(item):
		return
	
	var is_inventory_authority: bool = SimusNet.get_network_authority(slot.get_inventory()) == SimusNetRemote.sender_id
	var is_inventory_opened: bool = get_opened().has(slot.get_inventory())
	
	if is_inventory_authority or is_inventory_opened:
		if slot.is_free():
			if slot.can_handle_item(item):
				item.reparent(slot)

func _send() -> void:
	var bytes: PackedByteArray = CT_InventorySlot.serialize_array(get_slots())
	SimusNetRPC.invoke_on(SimusNetRemote.sender_id, _receive, bytes, _selected_slot)
	

func _receive(raw: PackedByteArray, _selected: CT_InventorySlot) -> void:
	for i in get_children():
		if i is CT_InventorySlot:
			i.queue_free()
			await i.tree_exited
	
	var slots: Array[CT_InventorySlot] = CT_InventorySlot.deserialize_array(raw)
	for i in slots:
		add_child(i)
	
	_selected_slot = _selected
	
	_do_network_ready()

func _do_network_ready() -> void:
	is_ready = true
	on_ready.emit()
	EVENT.on_inventory_ready.set_properties({"source" : self}).publish()
	if is_local():
		EVENT.on_inventory_ready_local.set_properties({"source" : self}).publish()

func _on_item_added(slot: CT_InventorySlot, item: CT_ItemStack) -> void:
	on_item_added.emit(slot, item)
	if !SimusNetConnection.is_server():
		return
	
	await get_tree().process_frame
	SimusNetRPC.invoke(_receive_item_add, slot, item.serialize())

func _on_item_removed(slot: CT_InventorySlot, item: CT_ItemStack) -> void:
	on_item_removed.emit(slot, item)
	
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

var _opened: Array[CT_Inventory]

func can_open_other_inventories() -> bool:
	return get_opened().is_empty()

func get_opened() -> Array[CT_Inventory]:
	var parsed: Array[CT_Inventory] = []
	for i in _opened:
		if is_instance_valid(i):
			parsed.append(i)
	_opened.clear()
	return parsed

func is_opened(inventory: CT_Inventory) -> bool:
	return get_opened().has(inventory)

func open(inventory: CT_Inventory) -> void:
	if SimusNetConnection.is_server():
		if is_opened(inventory) or !can_open_other_inventories():
			return
		
		SimusNetRPC.invoke_all(_open_server, inventory)

func _open_server(inventory: CT_Inventory) -> void:
	if !_opened.has(inventory) and can_open_other_inventories():
		_opened.append(inventory)
		on_inventory_opened.emit(inventory)
		EVENT.on_inventory_opened.source = self
		EVENT.on_inventory_opened.inventory = inventory
		EVENT.on_inventory_opened.publish()

func close(inventory: CT_Inventory) -> void:
	if SimusNetConnection.is_server():
		if not is_opened(inventory):
			return
		
		SimusNetRPC.invoke_all(_close_server, inventory)

func _close_server(inventory: CT_Inventory) -> void:
	if _opened.has(inventory):
		_opened.erase(inventory)
		on_inventory_closed.emit(inventory)
		EVENT.on_inventory_closed.source = self
		EVENT.on_inventory_closed.inventory = inventory
		EVENT.on_inventory_closed.publish()

func request_open(inventory: CT_Inventory) -> void:
	if is_opened(inventory) or !can_open_other_inventories():
		return
	
	SimusNetRPC.invoke_on_server(open, inventory)

func request_close(inventory: CT_Inventory) -> void:
	if not is_opened(inventory):
		return
	
	SimusNetRPC.invoke_on_server(close, inventory)

func request_close_all() -> void:
	for inv in get_opened():
			request_close(inv)
