extends Node
class_name CT_Furnace

@export var root: Node3D
@export var bake_speed: float = 1.0
@export var fuel_consumption: float = 1.0
@export var slots: int = 1

@export var _inventory: CT_Inventory
@export var _audio_player: AudioStreamPlayer3D

var _is_active: bool = false : set = set_active

func is_active() -> bool:
	return _is_active

func set_active(value: bool) -> void:
	_is_active = value
	
	await SD_Nodes.async_for_ready(self)
	if _is_active:
		_audio_player.play()
	else:
		_audio_player.stop()

func get_inventory() -> CT_Inventory:
	return _inventory

func _network_setup() -> void:
	SimusNetVars.register(self, [
		"_is_active",
		
	], SimusNetVarConfig.new().flag_tickrate(20)
	.flag_mode_server_only()
	.flag_replication()
	)

func _ready() -> void:
	if !root:
		root = get_parent()
	
	_network_setup()
	
	R_InteractAction.ACTION_OPEN.append_to(root)
	
	await SD_Nodes.async_for_ready(root)
	_inventory.clear_slots()
	
	
