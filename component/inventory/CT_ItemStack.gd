extends Node
class_name CT_ItemStack

@export var object: R_WorldObject
@export var stackable: bool = true
@export var quantity: int = 1 : 
	set(value):
		quantity = value
		on_quantity_changed.emit()
		if quantity < 1 and SimusNetConnection.is_server():
			queue_free()

@export var stack_size: int = 64

signal on_quantity_changed()

var _slot: CT_InventorySlot
var _inventory: CT_Inventory

func get_inventory() -> CT_Inventory:
	return _inventory

func _enter_tree() -> void:
	name = name.validate_node_name()
	_slot = SD_ECS.node_find_above_by_script(self, CT_InventorySlot)
	_slot._item_stack = self
	_slot.on_item_added.emit(self)
	_slot.on_updated.emit()
	
	_inventory = SD_ECS.node_find_above_by_script(self, CT_Inventory)
	SimusNetVisible.set_visibile(self, SimusNetVisible.get_or_create(_inventory))
	_inventory._on_item_added(_slot, self)
	
	_inventory._item_stacks.append(self)

func _exit_tree() -> void:
	_slot.on_item_removed.emit(self)
	_slot.on_updated.emit()
	_inventory._item_stacks.erase(self)
	_inventory._on_item_removed(_slot, self)
	_slot._item_stack = null

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
	
	var item_config: R_ItemStackConfig = object.get_itemstack_config()
	stackable = item_config.stackable
	stack_size = item_config.stack_size
	

static func create_from_object(_object: R_WorldObject) -> CT_ItemStack:
	var item: CT_ItemStack = _object.get_itemstack_config().get_item_script().new()
	item.object = _object
	return item

static func create_from_object_instance(instance: I_WorldObject) -> CT_ItemStack:
	var item: CT_ItemStack = instance.get_object().get_itemstack_config().get_item_script().new()
	item.object = instance.get_object()
	return item

func serialize() -> Dictionary:
	var data: Dictionary = {}
	data[-1] = SimusNetIdentity.server_serialize_instance(self)
	if get_script().get_global_name() != "CT_ItemStack":
		data[0] = SimusNetSerializer.parse_resource(get_script())
	
	name = name.validate_node_name()
	data[1] = name
	if object:
		data[2] = SimusNetSerializer.parse_resource(object)
	return data

static func deserialize(data: Dictionary) -> CT_ItemStack:
	var script: GDScript = data.get(0, CT_ItemStack)
	if !is_instance_valid(script):
		script = CT_ItemStack
	
	var item: CT_ItemStack = script.new()
	SimusNetIdentity.client_deserialize_instance(data[-1], item)
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
