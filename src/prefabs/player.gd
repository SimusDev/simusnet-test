extends CharacterBody3D
class_name Player

@onready var cube: MeshInstance3D = $Camera/cube

func _input(event: InputEvent) -> void:
	if not SimusNet.is_network_authority(self):
		return
	
	if Input.is_action_just_pressed("interact"):
		SimusNetRPC.invoke(switch_cube, load("uid://cqdfkwb1galvp"))


@onready var _switch_cube_rpc = SimusNetRPC.register([switch_cube], SimusNetRPCConfig.new().
flag_serialization())
func switch_cube(args: Variant) -> void:
	cube.visible = !cube.visible
