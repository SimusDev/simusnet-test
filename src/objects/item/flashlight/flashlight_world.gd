extends RigidBody3D

@export var object:R_WorldObject
@export var light:Light3D


func _ready() -> void:
	var rpc_cfg:SimusNetRPCConfig = SimusNetRPCConfig.new()
	
	SimusNetRPC.register(
		[_receive],
		rpc_cfg
	)
	
	
	
	if SimusNetConnection.is_server():
		object = I_WorldObject.find_in(self).get_object()
		SimusNetRPC.invoke_all(
			_receive,
			object.turned_on
		)

func _receive(object_visible:bool) -> void:
	light.visible = object_visible
