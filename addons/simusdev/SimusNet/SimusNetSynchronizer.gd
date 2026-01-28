@icon("./icons/MultiplayerSynchronizer.svg")
extends Node
class_name SimusNetSynchronizer

@export var data: Array[SimusNetSync] = []

func _ready() -> void:
	for sync in data:
		_initialize(sync)

func _initialize(sync: SimusNetSync) -> void:
	if sync.node.is_empty():
		return
	
	var config: SimusNetVarConfig = SimusNetVarConfig.new()
	config.flag_serialization(sync.serialization)
	config._mode = sync.mode
	
	if sync.reliable:
		config.flag_reliable(sync.channel)
	else:
		config.flag_unreliable(sync.channel)
	
	SimusNetVars.register(get_node(sync.node), PackedStringArray(sync.properties), config)
	config.flag_tickrate(sync.tickrate)
	config.flag_replication()
