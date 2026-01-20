extends Control
class_name UI_Backpack

var _player_inventory: CT_Inventory

@onready var _avatar_other: UI_InventoryAvatar = $_AvatarOther
@onready var _avatar_player: UI_InventoryAvatar = $_AvatarPlayer

@onready var _ui_backpack_custom: UI_BackpackCustom = $_OtherWindow/_UI_BackpackCustom

func _ready() -> void:
	_player_inventory = CT_Inventory.find_in(CT_Playable.get_local().node)
	_avatar_player.inventory = _player_inventory
	$player_slots.inventory = _player_inventory
	%player_cloth_slots.inventory = _player_inventory
	%player_hotbar_slots.inventory = _player_inventory
	
	if _player_inventory:
		_player_inventory.on_inventory_opened.connect(_on_player_inventory_opened)
		_player_inventory.on_inventory_closed.connect(_on_player_inventory_closed)

func _on_player_inventory_opened(inv: CT_Inventory) -> void:
	$SD_UIInterfaceMenu.open()
	for opened in _player_inventory.get_opened():
		if opened != inv:
			_player_inventory.request_close(opened)
	
	_avatar_other.inventory = inv
	_ui_backpack_custom._player_inventory = _player_inventory
	_ui_backpack_custom.inventory = inv

func _on_player_inventory_closed(inv: CT_Inventory) -> void:
	pass

func _on_draw() -> void:
	if !is_instance_valid(_player_inventory):
		return
	
	if !is_node_ready():
		await ready


func _on_hidden() -> void:
	if !is_instance_valid(_player_inventory):
		return
	
	if !is_node_ready():
		await ready
	
	_player_inventory.request_close_all()
	_avatar_other.inventory = null
	_ui_backpack_custom.inventory = null
