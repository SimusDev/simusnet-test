@tool
class_name ViewModelRoot3D extends Node3D

signal object_changed

@export var type: R_ViewModel.TYPE = R_ViewModel.TYPE.VIEW :
	set(val):
		type = val
		_update()
@export var object:R_WorldObject :
	set(new_object):
		object = new_object
		object_changed.emit()
		_update()
	get():
		return object

@export_group("Editor")
@export var enabled_in_editor:bool = true
@export_tool_button("Update", "CodeFoldedRightArrow") var btn_update = _update
@export_tool_button("Reset", "CodeFoldedRightArrow") var btn_clear = _clear.bind(false)

@export var _object_instance:Node3D

var _inventory: CT_Inventory

var _logger: SD_Logger = SD_Logger.new(self) 

func get_inventory() -> CT_Inventory:
	return _inventory

func _ready() -> void:
	_find_inventory()

func _find_inventory() -> void:
	if Engine.is_editor_hint():
		return
	
	_inventory = SD_ECS.node_find_above_by_component(self, CT_Inventory)
	
	if type == R_ViewModel.TYPE.VIEW:
		if !_inventory:
			_logger.debug("cant find inventory for viemodel type 'VIEW'", SD_ConsoleCategories.ERROR)
	
	if !_inventory.is_ready:
		await _inventory.on_ready
	
	_inventory.on_slot_selected.connect(_on_slot_updated_for_viewmodel)
	_inventory.on_item_added.connect(_inventory_on_item_added)
	_inventory.on_item_removed.connect(_inventory_on_item_removed)
	_on_slot_updated_for_viewmodel(_inventory.get_selected_slot())

func _on_slot_updated_for_viewmodel(slot: CT_InventorySlot, delete: bool = false) -> void:
	if is_instance_valid(slot):
		if delete:
			object = null
			return
		
		object = slot.get_object()
	

func _inventory_on_item_added(slot: CT_InventorySlot, item: CT_ItemStack) -> void:
	if _inventory.get_selected_slot() == slot:
		_on_slot_updated_for_viewmodel(slot)
	

func _inventory_on_item_removed(slot: CT_InventorySlot, item: CT_ItemStack) -> void:
	if _inventory.get_selected_slot() == slot:
		_on_slot_updated_for_viewmodel(slot, true)
	

func _clear(safe:bool = true) -> void:
	if not enabled_in_editor and Engine.is_editor_hint():
		return
	
	if safe:
		if not is_inside_tree():
			return
	
	if is_instance_valid(_object_instance):
		if _object_instance.is_queued_for_deletion():
			await _object_instance.tree_exited
	
	if is_instance_valid(_object_instance):
		_object_instance.queue_free()
		if _object_instance.is_inside_tree():
			await _object_instance.tree_exited
		_object_instance = null
	else:
		_object_instance = null
	

func _update() -> void:
	if not is_inside_tree():
		await tree_entered
	
	if not enabled_in_editor and Engine.is_editor_hint():
		return
	
	if not is_node_ready():
		await ready
	
	if not get_parent().is_node_ready():
		await get_parent().ready
	
	await _clear()
	
	if not object:
		_logger.debug("object is null", SD_ConsoleCategories.ERROR)
		return
	
	if not object.viewmodel:
		_logger.debug("viewmodel is null", SD_ConsoleCategories.ERROR)
		return
	
	var prefab: PackedScene = object.viewmodel.pick_prefab(type)
	
	if not prefab:
		_logger.debug("object prefab is null", SD_ConsoleCategories.ERROR)
		return
	
	_object_instance = prefab.instantiate()
	_object_instance.name = "view"
	_object_instance.set_multiplayer_authority(get_multiplayer_authority())
	
	if not Engine.is_editor_hint():
		object.set_in(_object_instance)
	
	add_child(_object_instance)
