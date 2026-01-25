extends Node
class_name VehicleSynchronizer

@export var vehicle: Vehicle
@export var camera: Camera3D

func _ready() -> void:
	if SimusNet.is_network_authority(self):
		await SD_Nodes.async_for_ready(vehicle)
		camera.make_current()
		camera.reparent(vehicle.get_parent())
