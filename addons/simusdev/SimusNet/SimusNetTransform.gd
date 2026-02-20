@icon("./icons/MultiplayerSynchronizer.svg")
@tool
extends SimusNetNode
class_name SimusNetTransform

@export var node: Node
@export var interpolate: bool = true : get = is_interpolated
@export var interpolate_speed: float = 15.0 : get = get_interpolate_speed

const _META: StringName = &"SimusNetTransform"

const _TP: StringName = &"transform"
const _PP: StringName = &"position"
const _RP: StringName = &"rotation"
const _SP: StringName = &"scale"

var _data: Dictionary[StringName, Variant] = {}

func is_interpolated() -> bool:
	return interpolate

func get_interpolate_speed() -> float:
	return interpolate_speed

func _ready() -> void:
	super()
	
	if !node:
		node = get_parent()
	
	if Engine.is_editor_hint() or not _TP in node:
		return
	
	node.set_meta(_META, self)
	
	SimusNetIdentity.register(self)
	
	_data = SimusNetSynchronization.get_synced_properties(self)
	
	set_process(is_instance_valid(node))

static func find_transform(target: Node) -> SimusNetTransform:
	if target.has_meta(_META):
		return target.get_meta(_META)
	return null

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if SimusNet.is_network_authority(self):
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
