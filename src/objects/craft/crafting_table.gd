extends RigidBody3D
class_name CraftingTable

@export var _ct_inventory: CT_Inventory

var _recipes: Array[R_Recipe] = []

func _ready() -> void:
	_recipes = R_Recipe.get_recipe_list()
	
	SimusNetRPC.register(
		[
			_request_rpc,
			
		], SimusNetRPCConfig.new().flag_mode_any_peer()
		.flag_set_channel(Network.CHANNEL_INVENTORY)
		.flag_serialization()
	)

func request() -> void:
	SimusNetRPC.invoke_on_server(_request_rpc)

func _request_rpc() -> void:
	try_craft()

func try_craft() -> void:
	if not SimusNetConnection.is_server():
		return
	
	for recipe in _recipes:
		pass
