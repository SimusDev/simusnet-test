@icon("./icons/MultiplayerSynchronizer.svg")
@tool
extends SimusNetNodeAutoVisible
class_name SimusNetTransform

@export var interpolate: bool = true
@export var interpolate_speed: float = 15.0

func _ready() -> void:
	super()
	
	if Engine.is_editor_hint():
		return
	
	if !node.is_node_ready():
		await node.ready
		SimusNetIdentity.register(self)
	
	SimusNetSynchronization._instance._transform_ready(self)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if SimusNet.is_network_authority(self):
		return
	
	var data: Dictionary[StringName, Variant] = SimusNetSynchronization.get_synced_properties(self)
	
	var position: Variant = data.get("position", node.position)
	var rotation: Variant = data.get("rotation", node.rotation)
	var scale: Variant = data.get("scale", node.scale)
	
	node.position = lerp(node.position, position, interpolate_speed * delta)
	node.rotation.x = lerp_angle(node.rotation.x, rotation.x, interpolate_speed * delta)
	node.rotation.y = lerp_angle(node.rotation.y, rotation.y, interpolate_speed * delta)
	if node.rotation is Vector3:
		node.rotation.z = lerp_angle(node.rotation.z, rotation.z, interpolate_speed * delta)
	node.scale = lerp(node.scale, scale, interpolate_speed * delta)
	

func _enter_tree() -> void:
	super()
	
	if Engine.is_editor_hint():
		return
	
	if !is_node_ready():
		await ready 
	SimusNetSynchronization._instance._transform_enter_tree(self)

func _exit_tree() -> void:
	super()
	
	if Engine.is_editor_hint():
		return
	
	SimusNetSynchronization._instance._transform_exit_tree(self)
