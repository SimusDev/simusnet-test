extends Node3D

func _ready() -> void:
	SimusNetRPC.register([
		_test
	],
	SimusNetRPCConfig.new().flag_mode_server_only().flag_serialization()
	)
	

func _on_timer_timeout() -> void:
	if SimusNetConnection.is_server():
		SimusNetRPC.invoke(_test, $Connection)
		

func _test(v1: Variant = null, v2: Variant = null, v3: Variant = null) -> void:
	print("%s hello from: %s" % [v1, SimusNetRemote.sender_id])
