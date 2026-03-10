class_name SimusNetContentLoader extends RefCounted

func _init() -> void:
	var rpc_cfg:SimusNetRPCConfig = SimusNetRPCConfig.new()
	SimusNetRPC.register(
		[
			
		],
		rpc_cfg
	)
	
	

func _send() -> void:
	pass

func _receive() -> void:
	pass
