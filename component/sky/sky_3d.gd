extends Node

@onready var sky_3d: Sky3D = $Sky3D

func _ready() -> void:
	SimusNetVars.register(sky_3d, 
	[
		"current_time",
		
	], SimusNetVarConfig.new().flag_mode_server_only()
	.flag_tickrate(0.1).flag_replication().flag_reliable(Network.CHANNEL_ENVIRONMENT)
	)
	
	SimusNetVars.register(sky_3d, 
	[
		"minutes_per_day",
		
	], SimusNetVarConfig.new().flag_mode_server_only()
	.flag_tickrate(1).flag_replication().flag_reliable(Network.CHANNEL_ENVIRONMENT)
	)
