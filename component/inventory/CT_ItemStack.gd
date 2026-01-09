extends Node
class_name CT_ItemStack

@export var object: R_WorldObject
@export var stackable: bool = true
@export var quantity: int = 1
@export var stack_size: int = 64

var _inventory: CT_Inventory

func get_slot() -> int:
	return get_index()

func get_inventory() -> CT_Inventory:
	return _inventory

func _enter_tree() -> void:
	_inventory = SD_ECS.node_find_above_by_script(self, CT_Inventory)
	SimusNetVisible.set_visibile(self, SimusNetVisible.get_or_create(_inventory))
	
	_inventory._items.append(self)

func _exit_tree() -> void:
	_inventory._items.erase(self)

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
	return data

static func deserialize(data: Dictionary) -> CT_ItemStack:
	var script: GDScript = data.get(0, CT_ItemStack)
	var item: CT_ItemStack = script.new()
	return item
