extends RigidBody3D
class_name CraftingTable

@export var _ct_inventory: CT_Inventory

var _recipes: Array[R_Recipe] = []

const INPUT_SLOTS: int = 9
const OUTPUT_SLOTS: int = 1
const COLUMNS: int = 3

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
	
	var picked_recipe: R_Recipe
	
	for recipe in _recipes:
		var matches: int = 0
		var input_match_slots: int = 0
		var input_match: int = 0
		
		var slot_id: int = -1
		for slot: CT_InventorySlot in _ct_inventory.get_slots_by_script(CT_InventorySlotInput):
			slot_id += 1
		
		
		
	
	if not picked_recipe:
		return
	
	var output_slots: Array[CT_InventorySlot] = _ct_inventory.get_slots_by_script(CT_InventorySlotOutput)
	for slot in output_slots:
		if slot.is_free():
			var item: CT_ItemStack = CT_ItemStack.create_from_object(picked_recipe.output)
			item.quantity = picked_recipe.output_quantity
			slot.add_child(item)
			return
	
	

func _is_matches(input: R_RecipeData, item: CT_ItemStack) -> bool:
	if input and item:
		if item.object == input.object:
			return true
		
		for input_tag in input.tags:
			if item.object.tags.has(input_tag):
				return true
		
	return false
