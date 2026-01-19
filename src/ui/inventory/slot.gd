extends Control
class_name UI_InventorySlot

var slot: CT_InventorySlot

var _item: CT_ItemStack

@export var _quantity: Label

const SCENE: PackedScene = preload("uid://bu532ooqgmkjg")

static func create(from: CT_InventorySlot) -> UI_InventorySlot:
	var ui: UI_InventorySlot = SCENE.instantiate()
	ui.slot = from
	return ui

func _ready() -> void:
	if !slot:
		return
	
	if slot.get_item_stack():
		_on_item_added(slot.get_item_stack())
	else:
		_on_item_removed(slot.get_item_stack())
	
	slot.on_item_added.connect(_on_item_added)
	slot.on_item_removed.connect(_on_item_removed)
	

func _on_item_added(item: CT_ItemStack) -> void:
	_item = item
	_item.on_quantity_changed.connect(_on_quantity_changed)
	
	$icon.texture = _item.object.icon
	_on_quantity_changed()


func _on_item_removed(item: CT_ItemStack) -> void:
	if _item:
		_item.on_quantity_changed.disconnect(_on_quantity_changed)
		_item = null
	
	$icon.texture = null
	
	_on_quantity_changed()

func _on_quantity_changed() -> void:
	if _item:
		_quantity.visible = _item.quantity > 1
		_quantity.text = str(_item.quantity)
	else:
		_quantity.hide()

func _on_sd_ui_drag_and_drop_dropped(draggable: Control, at: Control) -> void:
	if is_instance_valid(_item):
		if at is UI_InventorySlot:
			_item.get_inventory().try_move_item(_item, at.slot)
