extends R_Object
class_name R_WorldObject

@export var viewmodel: R_ViewModel : get = get_viewmodel

@export_group("ItemStack", "itemstack")
@export var itemstack_config: R_ItemStackConfig : get = get_itemstack_config

static var _world_objects: Dictionary[String, R_WorldObject]

static func get_world_object_list() -> Array[R_WorldObject]:
	return _world_objects.values()

static func find_by_id(value: String) -> R_WorldObject:
	return _world_objects.get(value)

func is_supports_gamestate() -> bool:
	return true

func _itemstack_config_init(config: R_ItemStackConfig) -> void:
	pass

func _itemstack_config_get(config: R_ItemStackConfig) -> void:
	pass

func get_itemstack_config() -> R_ItemStackConfig:
	if !itemstack_config:
		itemstack_config = R_ItemStackConfig.new()
		_itemstack_config_init(itemstack_config)
	_itemstack_config_get(itemstack_config)
	return itemstack_config



static func find_in(node: Node) -> R_WorldObject:
	if node.has_meta("R_WorldObject"):
		return node.get_meta("R_WorldObject")
	return null

func set_in(node: Node) -> void:
	node.set_meta("R_WorldObject", self)

func _registered() -> void:
	super()
	_world_objects[id] = self

func _unregistered() -> void:
	super()
	_world_objects.erase(id)

func get_viewmodel() -> R_ViewModel:
	if !viewmodel:
		viewmodel = R_ViewModel.new()
	return viewmodel
