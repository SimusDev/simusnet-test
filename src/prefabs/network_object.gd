extends Node3D

@export var sync_var: String = ""

func _ready() -> void:
	SimusNetConnection.connect_network_node_callables(self, _connect, _disconnect, func(): pass)

func _physics_process(delta: float) -> void:
	if SimusNet.is_network_authority(self):
		SimusNetVars.send(self, ["sync_var"], false)

func _connect() -> void:
	if SimusNetConnection.is_server():
		$AnimationPlayer.speed_scale = SD_Random.get_rfloat_range(0.5, 2.0)
		$AnimationPlayer.play("idle")

func _disconnect() -> void:
	$AnimationPlayer.stop()
