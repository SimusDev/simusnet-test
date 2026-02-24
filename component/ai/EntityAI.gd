class_name EntityAI extends Node

@export var root:Node3D

@export var state_machine:SD_FiniteStateMachine
@export var ct_tick:CT_Tick

@export_range(-1, 1) var look_direction:int = -1

var _logger:SD_Logger
var eye_rays:Array[AI_EyeRay]

func _ready() -> void:
	_logger = SD_Logger.new("EntityAI")
	
	if not SimusNetConnection.is_server():
		return
	
	if not ct_tick:
		_logger.debug("ct_tick is null", SD_ConsoleCategories.CATEGORY.ERROR)
		return
	
	ct_tick.tick.connect(_on_tick)
	EVENT.on_player_spawned.listen(_create_ray_for_peer)
	


func _create_ray_for_peer() -> void:
	var peer:int = EVENT.on_player_spawned.playable.get_peer_id()
	
	for ray:AI_EyeRay in eye_rays:
		if ray.target_peer == peer:
			_logger.debug("AI_EyeRay for peer: '%s' already exists" % [peer])
			return
			
	var new_ray:AI_EyeRay = AI_EyeRay.new()
	
	new_ray.tree_exiting.connect(
		func():
			if eye_rays.has(new_ray):
				eye_rays.erase(new_ray)
	)
	
	var entity_head:CT_EntityHead = CT_EntityHead.find_above(root)
	if entity_head:
		var entity_eyes = entity_head.get_eyes()
		if entity_eyes:
			entity_eyes.add_child(new_ray)
	else:
		root.add_child(new_ray)
	
	new_ray.target_position = Vector3(0.0, 0.0, 5.0 * look_direction)
	new_ray.target_peer = peer
	eye_rays.append(new_ray)
	ct_tick.tick.connect(new_ray.update)


func _on_tick() -> void:
	pass
