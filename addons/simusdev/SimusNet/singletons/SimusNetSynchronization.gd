extends SimusNetSingletonChild
class_name SimusNetSynchronization

static var _instance: SimusNetSynchronization

var _transforms: Array[SimusNetTransform] = []

var _timer_transform: Timer

func _init() -> void:
	_instance = self

static func get_synced_properties(object: Object) -> Dictionary[StringName, Variant]:
	return SD_Variables.get_or_add_object_meta(object, &"simusnetspynced", {} as Dictionary[StringName, Variant])

static func get_changed_properties(object: Object) -> Dictionary[StringName, Variant]:
	return SD_Variables.get_or_add_object_meta(object, &"simusnetpchange", {} as Dictionary[StringName, Variant])

func initialize() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	_instance = self
	
	_timer_transform = Timer.new()
	_timer_transform.wait_time = 1.0 / singleton.settings.synchronization_transform_tickrate
	_timer_transform.timeout.connect(_on_transform_tick)
	add_child(_timer_transform)
	
	SimusNetEvents.event_connected.listen(_on_connected)
	SimusNetEvents.event_disconnected.listen(_on_disconnected)
	
	SimusNetRPCGodot.register_any_peer_unreliable(
		[_recieve_transform], SimusNetChannels.BUILTIN.TRANSFORM
	)

func _on_connected() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_timer_transform.start()

func _on_disconnected() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	_timer_transform.stop()

func _on_transform_tick() -> void:
	_timer_transform.wait_time = 1.0 / singleton.settings.synchronization_transform_tickrate
	var data: Dictionary = {}
	
	#if SimusNetConnection.is_server():
		#print(_transforms)
	
	for transform in _transforms:
		
		
		if !SimusNet.is_network_authority(transform):
			continue
		
		var identity: SimusNetIdentity = SimusNetIdentity.register(transform)
		if !identity.is_ready:
			continue
		
		for peer in transform.get_peers():
			if peer == SimusNetConnection.get_unique_id():
				continue
			
			
			var identities: Dictionary = data.get(peer, {})
			var properties: Dictionary = identities.get_or_add(identity.try_serialize_into_variant(), {})
			_parse_property_sender(transform, properties, "position", transform.node.position)
			_parse_property_sender(transform, properties, "rotation", transform.node.rotation)
			_parse_property_sender(transform, properties, "scale", transform.node.scale)
			
			if !properties.is_empty():
				data[peer] = identities
				#print("[%s]: %s" % [SimusNetConnection.is_server(), identities])
	
	for peer: int in data:
		#if SimusNetConnection.is_server():
			#print(SimusNetCompressor.parse(var_to_bytes(data[peer])).size())
			#print(var_to_bytes(data[peer]).size())
		_recieve_transform.rpc_id(peer, SimusNetCompressor.parse(data[peer]))

func _parse_property_sender(object: Object, properties: Dictionary, property: String, current_value: Variant) -> void:
	var change_hook: Dictionary = get_changed_properties(object)
	
	if change_hook.get_or_add(property, current_value) == current_value:
		return
	
	
	properties[SimusNetVars.try_serialize_into_variant(property)] = current_value
	change_hook.set(property, current_value)

func _parse_properties_receiver(properties: Dictionary) -> void:
	for identity_id: int in properties:
		var identity: SimusNetIdentity = SimusNetIdentity.try_deserialize_from_variant(identity_id)
		if identity:
			var node: SimusNetTransform = identity.owner
			if SimusNet.get_network_authority(node) == multiplayer.get_remote_sender_id():
				var serialized_properties: Dictionary = properties[identity_id]
				for p in serialized_properties:
					var property: String = SimusNetVars.try_deserialize_from_variant(p)
					#print(property)
					get_synced_properties(node).set(property, serialized_properties[p])
					if !node.interpolate:
						node.node.set(property, serialized_properties[p])


func _on_vars_tick() -> void:
	pass

func _recieve_transform(packet: Variant) -> void:
	var data: Dictionary = SimusNetDecompressor.parse(packet)
	_parse_properties_receiver(data)

func _transform_ready(transform: SimusNetTransform) -> void:
	pass

func _transform_enter_tree(transform: SimusNetTransform) -> void:
	if _transforms.has(transform):
		return
	
	_transforms.append(transform)

func _transform_exit_tree(transform: SimusNetTransform) -> void:
	_transforms.erase(transform)
