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
	var data: Array = []
	SimusNetRPC.invoke_on(SimusNetRemote.sender_id, _receive, SD_Variables.compress(data))

func _receive(compressed: Variant) -> void:
	var data: Array = SD_Variables.decompress(compressed)
	print(data)
