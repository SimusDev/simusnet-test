extends W_Item

@export var light:Light3D


func _ready() -> void:
	super()
	if not object:
		return
	
	var rpc_cfg = SimusNetRPCConfig.new()
	SimusNetRPC.register(
		[
			_receive
		],
		rpc_cfg
	)
	
	light.visible = object.turned_on
	
	if SimusNetConnection.is_server():
		SimusNetRPC.invoke_all(
			_receive,
			object.turned_on
		)

func request_press() -> void:
	super()
	
	if not SimusNetConnection.is_server():
		return
	
	if not object:
		return
	
	
	object.turned_on = !object.turned_on
	
	
	SimusNetRPC.invoke_all(
		_receive,
		object.turned_on
	)

func _receive(object_visible:bool) -> void:
	light.visible = object_visible
