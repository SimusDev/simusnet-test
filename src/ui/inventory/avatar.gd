extends Control
class_name UI_InventoryAvatar

@export var inventory: CT_Inventory : set = set_inventory

@onready var _icon: TextureRect = $_icon

func set_inventory(new: CT_Inventory) -> void:
	inventory = new
	if !is_node_ready():
		await ready
	
	update()

func update() -> void:
	_icon.texture = null
	
	if !is_instance_valid(inventory):
		return
	
	
	if !inventory.is_ready:
		await inventory.on_ready
	
	var user: CT_User = CT_User.find_above(inventory)
	
	if user:
		_icon.texture = user.get_avatar()
		return
	
	var w_object: I_WorldObject = I_WorldObject.find_in(inventory.node)
	if w_object:
		_icon.texture = w_object.get_object().get_icon()
		return
