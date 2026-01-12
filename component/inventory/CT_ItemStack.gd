extends Node
class_name CT_ItemStack

@export var object: R_WorldObject
@export var stackable: bool = true
@export var quantity: int = 1
@export var stack_size: int = 64

var _slot: CT_InventorySlot
var _inventory: CT_Inventory

func get_inventory() -> CT_Inventory:
	return _inventory

func _enter_tree() -> void:
	_slot = SD_ECS.node_find_above_by_script(self, CT_InventorySlot)
	_slot._item_stack = self
	
	_inventory = SD_ECS.node_find_above_by_script(self, CT_Inventory)
	SimusNetVisible.set_visibile(self, SimusNetVisible.get_or_create(_inventory))
	
	_inventory._item_stacks.append(self)

func _exit_tree() -> void:
	_slot._item_stack = null
	_inventory._item_stacks.erase(self)

func _ready() -> void:
	SimusNetVars.register(
		self,
		[
			"stackable",
			"quantity",
			"stack_size",
			
		], 
		SimusNetVarConfig.new().flag_reliable(Network.CHANNEL_INVENTORY).
		flag_mode_server_only().flag_replication()
	)
	
	


func serialize() -> Dictionary:
	var data: Dictionary = {}
	if get_script().get_global_name() != "CT_ItemStack":
		data[0] = SimusNetSerializer.parse_resource(get_script())
	data[1] = name
	if object:
		data[2] = SimusNetSerializer.parse_resource(object)
	return data

static func deserialize(data: Dictionary) -> CT_ItemStack:
	var script: GDScript = data.get(0, CT_ItemStack)
	var item: CT_ItemStack = script.new()
	item.name = data[1]
	
	var _object: Variant = data.get(2, null)
	if _object:
		item.object = SimusNetDeserializer.parse_resource(_object)
	
	return item

static func serialize_array(array: Array[CT_ItemStack]) -> PackedByteArray:
	var result: Array = []
	for i in array:
		result.append(i.serialize())
	return SD_Variables.compress(result)

static func deserialize_array(bytes: PackedByteArray) -> Array[CT_ItemStack]:
	var result: Array[CT_ItemStack] = []
	for i in SD_Variables.decompress(bytes):
		result.append(deserialize(i))
	return result
