@icon("./icons/MultiplayerSynchronizer.svg")
@tool
extends SimusNetNode
class_name SimusNetTransform

@export var node: Node
@export var enabled: bool = true
@export var interpolate: bool = true : get = is_interpolated
@export var interpolate_speed: float = 15.0 : get = get_interpolate_speed
@export var tickrate: float = 32.0 : get = get_tickrate
@export var server_authorative: bool = false

var _tickrate_time: float = 0.0

const _META: StringName = &"SimusNetTransform"

const _TP: StringName = &"transform"
const _PP: StringName = &"position"
const _RP: StringName = &"rotation"
const _SP: StringName = &"scale"

var _data: Dictionary[StringName, Variant] = {}

var _identity: SimusNetIdentity

func get_tickrate() -> float:
	return tickrate

func _hook_position_snapshot() -> bool:
	var p: bool = _data.get_or_add(_PP, node.position) != node.position
	_data.set(_PP, node.position)
	return p

func _hook_rotation_snapshot() -> bool:
	var p: bool = _data.get_or_add(_RP, node.rotation) != node.rotation
	_data.set(_RP, node.rotation)
	return p

func _hook_scale_snapshot() -> bool:
	var p: bool = _data.get_or_add(_SP, node.scale) != node.scale
	_data.set(_SP, node.scale)
	return p

func get_multiplayer_authority() -> int:
	if server_authorative:
		return 1
	return super()

func set_multiplayer_authority(id: int, recursive: bool = true) -> void:
	if server_authorative:
		super(1, recursive)
	else:
		super(id, recursive)

func is_interpolated() -> bool:
	return interpolate

func get_interpolate_speed() -> float:
	return interpolate_speed

func _ready() -> void:
	super()
	
	if server_authorative:
		set_multiplayer_authority(1, false)
	
	if !node:
		node = get_parent()
	
	if Engine.is_editor_hint() or not _TP in node:
		return
	
	set_process(false)
	
	node.set_meta(_META, self)
	
	_identity = SimusNetIdentity.register(self)
	if !_identity.is_ready:
		await _identity.on_ready
	
	_data = SimusNetSynchronization.get_synced_properties(self)
	
	set_process(is_instance_valid(node))

static func find_transform(target: Node) -> SimusNetTransform:
	if target.has_meta(_META):
		return target.get_meta(_META)
	return null

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or !enabled:
		return
	
	if SimusNet.is_network_authority(self):
		_tickrate_time += delta
		if _tickrate_time >= 1.0 / tickrate:
			_tickrate_time = 0
			SimusNetSynchronization._instance._transform_tick(self)
		
		return
	
	var p: Variant = _data.get(_PP, node.position)
	var r: Variant = _data.get(_RP, node.rotation)
	var s: Variant = _data.get(_SP, node.scale)
	
	var i: float = interpolate_speed * delta
	
	node.position = node.position.lerp(p, i)
	node.rotation.x = lerp_angle(node.rotation.x, r.x, i)
	node.rotation.y = lerp_angle(node.rotation.y, r.y, i)
	
	if typeof(node.rotation) == TYPE_VECTOR3:
		node.rotation.z = lerp_angle(node.rotation.z, r.z, i)
	
	node.scale = node.scale.lerp(s, i)

func _enter_tree() -> void:
	if Engine.is_editor_hint() or !node:
		return
	
	if !is_node_ready():
		await ready 
	
	if _TP in node:
		SimusNetSynchronization._instance._transform_enter_tree(self)

func _exit_tree() -> void:
	if Engine.is_editor_hint() or !node:
		return
	
	if _TP in node:
		SimusNetSynchronization._instance._transform_exit_tree(self)
