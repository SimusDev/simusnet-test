class_name R_WeaponFirearm extends R_Item

@export var range:float = 250.0
@export var ammo: R_WorldObject
@export var ammo_max: int = 30

@export var reload_time: float = 5.0

@export_group("Audio")
@export var shot_sound:R_SoundObject

static func get_group() -> String:
	return "weapon"

func get_itemstack_config() -> R_ItemStackConfig:
	var config: R_ItemStackConfig = R_ItemStackConfig.new()
	config.set_item_script(CT_ItemStackFireArmWeapon)
	config.stackable = false
	return config
