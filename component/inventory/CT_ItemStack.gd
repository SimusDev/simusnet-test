extends Resource
class_name CT_ItemStack

@export var object: R_WorldObject
@export var stackable: bool = true
@export var quantity: int = 1
@export var stack_size: int = 64

var _inventory: CT_Inventory

var is_ready: bool = false

func get_inventory() -> CT_Inventory:
	return _inventory

func set_inventory(inventory: CT_Inventory) -> CT_ItemStack:
	var identity: SimusNetIdentity = SimusNetIdentity.register(self)
	identity.set_generated_unique_id(str(inventory.get_path()))
	if !is_ready:
		_ready()
	
	return self

func _ready() -> void:
	is_ready = true
	
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
