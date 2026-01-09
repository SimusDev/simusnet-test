extends SimusNetNode
class_name CT_Inventory

var _items: Array[CT_ItemStack]

func get_items() -> Array[CT_ItemStack]:
	return _items

func _ready() -> void:
	super()
	_network_setup()

func _network_ready() -> void:
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
	SimusNetRPC.invoke_on(SimusNetRemote.sender_id, _receive, CT_ItemStack.serialize_array(_items))

func _receive(raw: PackedByteArray) -> void:
	for i in get_children():
		if i is CT_ItemStack:
			i.queue_free()
			await i.tree_exited
		
	var data: Array[CT_ItemStack] = CT_ItemStack.deserialize_array(raw)
	for item in data:
		add_child(item)
	
