extends Node
class_name SimusNetSingleton

@onready var settings: SimusNetSettings = SimusNetSettings.get_or_create()

@export var garbage_collector: SimusNetGarbageCollector
@export var profiler: SimusNetProfiler
@export var events: SimusNetEvents
@export var cache: SimusNetCache
@export var channels: SimusNetChannels
@export var connection: SimusNetConnection
@export var time: SimusNetTime
@export var handshake: SimusNetHandShake
@export var methods: SimusNetMethods
@export var RPC: SimusNetRPC
@export var RPCgodot: SimusNetRPCGodot
@export var visibility: SimusNetVisibility
@export var resources: SimusNetResources
@export var vars: SimusNetVars
@export var synchronization: SimusNetSynchronization

var info: Node

var api: SceneMultiplayer

var __static_class_list: Array[Object] = [
	SimusNet.new(),
	SimusNetArguments.new(),
	SimusNetDictionarySerializer.new()
]

static var _instance: SimusNetSingleton

static func get_instance() -> SimusNetSingleton:
	return _instance

func _ready() -> void:
	var serializer: SimusNetSerializer = SimusNetSerializer.new()
	var serializer_weak_ref: WeakRef = weakref(serializer)
	__static_class_list.append(serializer_weak_ref)
	serializer._instance = serializer_weak_ref 
	__static_class_list.append(serializer)
	
	var deserializer: SimusNetDeserializer = SimusNetDeserializer.new()
	var deserializer_weak_ref: WeakRef = weakref(deserializer)
	__static_class_list.append(deserializer_weak_ref)
	deserializer._instance = deserializer_weak_ref
	__static_class_list.append(deserializer)
	
	info = SimusNetInfo.new()
	_set_active(false, true)
	get_tree().root.add_child.call_deferred(info)
	
	if !get_tree().get_multiplayer() is SceneMultiplayer:
		get_tree().set_multiplayer(SceneMultiplayer.new())
	
	api = get_tree().get_multiplayer()
	
	SimusNetSingletonChild.singleton = self
	
	for i in get_children():
		if i is SimusNetSingletonChild:
			i.logger = SimusNetLogger.create_for(i.get_script().get_global_name())
			i.logger.enabled = settings.debug_enable
			i.initialize()
	
	_instance = self
	SimusNetEvents.event_singleton_initialized.publish()

func _set_active(value: bool, server: bool) -> void:
	if value == false:
		info.name = "Not Active"
		return
	
	if server:
		info.name = "Server"
	else:
		info.name = "Client"
