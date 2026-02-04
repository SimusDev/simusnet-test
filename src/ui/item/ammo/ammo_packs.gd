@tool
extends Panel

@export var pack: R_AmmoPack : set = set_pack
@export var _container: Control
@export var _ammo_scene: PackedScene

@onready var _unload_weapon_button: Button = $UnloadWeapon

var _item: W_WeaponFirearm

func set_item(item: W_WeaponFirearm) -> void:
	if is_instance_valid(_item):
		_item._get_stack().on_ammo_changed.disconnect(_update_itemstack)
		_item._get_stack().on_bullets_changed.disconnect(_update_itemstack)
	
	_item = item
	
	_item._get_stack().on_ammo_changed.connect(_update_itemstack)
	_item._get_stack().on_bullets_changed.connect(_update_itemstack)

func _update_itemstack() -> void:
	_unload_weapon_button.disabled = true
	
	if !is_instance_valid(_item):
		return
	
	var stack: CT_ItemStackFireArmWeapon = _item._get_stack()
	if !is_instance_valid(stack):
		return
	
	
	var can_unload_weapon: bool = stack.bullets > 0
	_unload_weapon_button.disabled = !can_unload_weapon

func set_pack(new: R_AmmoPack) -> void:
	pack = new
	if !is_node_ready():
		await ready
	
	await SD_Nodes.async_clear_all_children(_container)
	
	if !is_instance_valid(pack):
		return
	
	for i in new.list:
		if i:
			var ui: Button = _ammo_scene.instantiate()
			ui.ref = i
			ui._item = _item
			_container.add_child(ui)
			ui.update()
			
			if Engine.is_editor_hint():
				ui.owner = get_tree().edited_scene_root

func _on_unload_weapon_pressed() -> void:
	pass # Replace with function body.
