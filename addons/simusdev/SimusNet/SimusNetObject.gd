extends Resource
class_name SimusNetObject

var _multiplayer_authority: int = SimusNetConnection.SERVER_ID

@export var uuid: Variant : set = set_uuid

var identity: SimusNetIdentity

var _is_queued_for_deletion: bool = false

var _node: Node

var _created: bool = false

func get_node() -> Node:
	return _node

func is_queued_for_deletion() -> bool:
	return _is_queued_for_deletion

func set_uuid(new: Variant) -> SimusNetObject:
	uuid = new
	return self

func set_multiplayer_authority(id: int, recursive: bool = true) -> void:
	_multiplayer_authority = id

func get_multiplayer_authority() -> int:
	return _multiplayer_authority

func create_instance() -> void:
	if _created:
		return
	
	identity = SimusNetIdentity.register(self, SimusNetIdentitySettings.new().set_unique_id(uuid))
	identity._tree_entered()
	if !identity.is_ready:
		await identity.on_ready
	_ready()

func delete_instance() -> void:
	if !_created:
		return
	
	_is_queued_for_deletion = true
	identity._tree_exited()

func _ready() -> void:
	pass

func queue_free() -> void:
	delete_instance()
