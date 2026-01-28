extends Node3D
class_name CT_Seat

@export var _interactable: RigidBody3D

@export var entity_invisible: bool = false

var _mounted_entity: Node3D : set = _set_mounted_entity

signal on_entity_mounted(entity: Node3D)
signal on_entity_unmounted(entity: Node3D)

var _remote_transform: RemoteTransform3D

var ACTION: R_InteractAction

func _ready() -> void:
	ACTION = load("res://src/objects/interact/actions/seat.tres")
	
	_remote_transform = RemoteTransform3D.new()
	add_child(_remote_transform)
	
	if _interactable:
		ACTION.append_to(_interactable)
	
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
	.flag_serialization()
	.flag_replication()
	)
	
	if _interactable:
		SD_ECS.append_to(_interactable, self)
	
func _set_mounted_entity(entity: Node3D) -> void:
	if get_mounted_entity():
		_entity_unmounted(get_mounted_entity())
	
	_mounted_entity = entity
	
	if !is_instance_valid(_mounted_entity):
		return
	
	_entity_mounted(_mounted_entity)

func _entity_mounted(entity: Node3D) -> void:
	if entity_invisible:
		entity.visible = false
	
	CT_LocalInput.get_or_create(entity).on_input.connect(_on_local_input)
	
	_remote_transform.remote_path = _remote_transform.get_path_to(entity)
	on_entity_mounted.emit(entity)

func _entity_unmounted(entity: Node3D) -> void:
	if entity_invisible:
		entity.visible = true
	
	CT_LocalInput.get_or_create(entity).on_input.disconnect(_on_local_input)
	
	_remote_transform.remote_path = NodePath()
	on_entity_unmounted.emit(entity)

func _on_local_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("jump"):
		try_interact()

func _physics_process(delta: float) -> void:
	if !get_mounted_entity():
		return
	
	#_mounted_entity.global_position = self.global_position
	#_mounted_entity.global_rotation.x = self.global_position.x
	#_mounted_entity.global_rotation.z = self.global_position.z

func set_mounted_entity(entity: Node3D) -> CT_Seat:
	if SimusNetConnection.is_server():
		_mounted_entity = entity
	return self

func get_mounted_entity() -> Node3D:
	if !is_instance_valid(_mounted_entity):
		if _mounted_entity != null:
			_mounted_entity = null
		return null
	
	return _mounted_entity

func mount(entity: Node3D) -> void:
	if !SimusNetConnection.is_server():
		return
	
	if get_mounted_entity():
		return
	
	_mounted_entity = entity

func unmount() -> void:
	if !SimusNetConnection.is_server():
		return
	
	if !get_mounted_entity():
		return
	
	_mounted_entity = null

func try_interact() -> void:
	var player: CT_Playable = CT_Playable.get_local()
	if player:
		SimusNetRPC.invoke_on_server(_try_interact_server, player.node)

func _try_interact_server(entity: Node3D) -> void:
	if !is_instance_valid(entity):
		return
	
	if get_mounted_entity() == entity:
		unmount()
	else:
		set_mounted_entity(entity)
	
	
