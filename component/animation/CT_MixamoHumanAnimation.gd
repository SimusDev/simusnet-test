@tool
extends Node
class_name CT_MixamoHumanAnimation

@export var model: W_AnimatedModel3D
@export var look_at_position: Vector3 = Vector3.ZERO
@export var look_at_range: float = 25.0

var _logger: SD_Logger = SD_Logger.new(self)

var _actor: CharacterBody3D

var _legs_playback: AnimationNodeStateMachinePlayback

var _look_at_modifier: LookAtModifier3D

var _entity_head: CT_EntityHead

func _ready() -> void:
	_init_look_at_modifier()
	
	if Engine.is_editor_hint():
		return
	
	if SimusNetConnection.is_dedicated_server():
		model.hide()
		model.tree.active = false
		return
	
	if !model:
		_logger.debug("cant find W_AnimatedModel3D reference!", SD_ConsoleCategories.ERROR)
		return
	
	model.visible = !SimusNet.is_network_authority(model)
	
	_legs_playback = model.get_tree_parameter("parameters/Legs/playback")
	
	_find_movement()
	_find_animation_events()
	_find_actor()

func _init_look_at_modifier() -> void:
	if !model:
		_logger.debug("init_look_at_modifier(): model reference is null!, set the reference and restart scene.", SD_ConsoleCategories.ERROR)
		return
	
	if !model.is_node_ready():
		await model.ready
	
	await get_tree().process_frame
	
	_look_at_modifier = LookAtModifier3D.new()
	model.skeleton.add_child(_look_at_modifier)
	_look_at_modifier.target_node = _look_at_modifier.get_path_to(_look_at_modifier)
	_look_at_modifier.bone_name = "mixamorig_Spine"
	_entity_head = CT_EntityHead.find_above(self)

func _process_look_at(delta: float) -> void:
	if !is_instance_valid(_look_at_modifier):
		return
	
	if Engine.is_editor_hint():
		_look_at_modifier.position = look_at_position
		
	
	if is_instance_valid(_entity_head):
		_look_at_modifier.position = _entity_head.get_eyes().position
		_look_at_modifier.position.y = _entity_head.get_eyes().rotation_degrees.x 
		#print(_look_at_modifier.position)
		
	
	_look_at_modifier.position.z += look_at_range

func _find_actor() -> void:
	_actor = SD_ECS.node_find_above_by_class(self, "CharacterBody3D")

var _lerp_blend_pos: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	_process_look_at(delta)
	
	if !is_instance_valid(_actor):
		return
	
	var norm_velocity: Vector3 = _actor.velocity * _actor.transform.basis
	var blend_pos: Vector2 = Vector2(norm_velocity.x, -norm_velocity.z)
	_lerp_blend_pos = lerp(_lerp_blend_pos, blend_pos, 10 * delta)
	
	model.set_tree_parameter("parameters/Legs/walk/Blend/blend_position", _lerp_blend_pos)
	model.set_tree_parameter("parameters/Legs/run/Blend/blend_position", _lerp_blend_pos)
	model.set_tree_parameter("parameters/Legs/crouch/Blend/blend_position", _lerp_blend_pos)
	
	var legs_timescale: float = _actor.velocity.length() * 0.25
	if legs_timescale < 1.0:
		legs_timescale = 1
	model.set_tree_parameter("parameters/LegsTimeScale/scale", legs_timescale)
	

func _on_movement_state_transitioned(from: SD_State, to: SD_State) -> void:
	if !is_instance_valid(to):
		return
	
	#print(to.name)
	match to.name:
		"ground":
			_legs_playback.travel("idle")
		"walk":
			_legs_playback.travel("walk")
		"run":
			_legs_playback.travel("run")
		"crouched":
			_legs_playback.travel("crouch")
		"crouched_walk":
			_legs_playback.travel("crouch")
		"crouched_run":
			_legs_playback.travel("crouch")

func _find_movement() -> void:
	await get_tree().process_frame
	var movement: W_FPCSourceLikeMovement = SD_ECS.node_find_above_by_component(self, W_FPCSourceLikeMovement)
	if movement:
		movement.state_machine.transitioned.connect(_on_movement_state_transitioned)
		_on_movement_state_transitioned(null, movement.get_current_state())

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
