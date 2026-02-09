extends Node
class_name CT_MixamoHumanAnimation

@export var model: W_AnimatedModel3D

var _logger: SD_Logger = SD_Logger.new(self)

func _ready() -> void:
	if SimusNetConnection.is_dedicated_server():
		model.hide()
		model.tree.active = false
		return
	
	if !model:
		_logger.debug("cant find W_AnimatedModel3D reference!", SD_ConsoleCategories.ERROR)
		return
	
	model.visible = !SimusNet.is_network_authority(model)
	_find_movement()
	_find_animation_events()

func _find_movement() -> void:
	await get_tree().process_frame
	var movement: W_FPCSourceLikeMovement = SD_ECS.node_find_above_by_component(self, W_FPCSourceLikeMovement)
	if movement:
		movement.state_machine.transitioned.connect(_on_movement_state_transitioned)

func _find_animation_events() -> void:
	var events: CT_AnimationEventsCharacter = await CT_AnimationEventsCharacter.async_find_above(self)
	if !events:
		return
	
	events.get_or_create("firearm_shoot").listen(_on_firearm_shoot, true)
	events.get_or_create("firearm_reload").listen(_on_firearm_reload, true)
	events.get_or_create("weapon_melee_swing").listen(_on_weapon_melee_swing, true)

func _on_firearm_shoot(event: EVENT) -> void:
	var item: W_WeaponFirearm = event.get_arguments()

func _on_firearm_reload(event: EVENT) -> void:
	var item: W_WeaponFirearm = event.get_arguments()

func _on_weapon_melee_swing(event: EVENT) -> void:
	var item: W_WeaponMelee = event.get_arguments()

func _on_movement_state_transitioned(from: SD_State, to: SD_State) -> void:
	pass
	
