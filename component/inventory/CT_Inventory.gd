extends SimusNetNode
class_name CT_Inventory

var _item_stacks: Array[CT_ItemStack]
var _slots: Array[CT_InventorySlot]

@export var initial_slot_count: int = 16

func get_item_stacks() -> Array[CT_ItemStack]:
	return _item_stacks

func get_slot_script() -> GDScript:
	return CT_InventorySlot

func get_slots() -> Array[CT_InventorySlot]:
	return _slots

func _ready() -> void:
	_network_setup()
	super()

func _network_ready() -> void:
	super()
	if !SimusNetConnection.is_server():
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
			_receive
		], SimusNetRPCConfig.new().flag_mode_server_only().flag_set_channel(Network.CHANNEL_INVENTORY)
	)
	

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
	
	
