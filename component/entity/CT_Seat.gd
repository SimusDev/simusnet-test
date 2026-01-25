extends Node3D
class_name CT_Seat

@export var _interactable: RigidBody3D

@export var entity_invisible: bool = false

var _mounted_entity: Node3D : set = _set_mounted_entity

func _ready() -> void:
	if _interactable:
		SD_ECS.append_to(_interactable, self)
	
	SimusNetRPC.register(
		[
			
		], 
		SimusNetRPCConfig.new()
		.flag_mode_any_peer()
		.flag_serialization()
		.flag_set_channel(Network.CHANNEL_INTERACTABLES)
	)
	
	SimusNetRPC.register(
		[
			_try_interact_server,
		], 
		SimusNetRPCConfig.new()
		.flag_mode_server_only()
		.flag_serialization()
		.flag_set_channel(Network.CHANNEL_INTERACTABLES)
	)
	
	SimusNetVars.register(self,
	["_mounted_entity"],
	SimusNetVarConfig.new().flag_mode_server_only().
	flag_reliable(Network.CHANNEL_INTERACTABLES)
	.flag_serialize()
	.flag_replication()
	)

func _set_mounted_entity(entity: Node3D) -> void:
	_mounted_entity = entity
	
	if !is_instance_valid(_mounted_entity):
		return

func get_mounted_entity() -> Node3D:
	return _mounted_entity

func mount(entity: Node3D) -> void:
	if !SimusNetConnection.is_server():
		return

func unmount() -> void:
	if !SimusNetConnection.is_server():
		return

func try_interact() -> void:
	var player: CT_Playable = CT_Playable.get_local()
	if player:
		SimusNetRPC.invoke_on_server(_try_interact_server, player.node)

func _try_interact_server(entity: Node3D) -> void:
	pass
