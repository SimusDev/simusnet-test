extends Node3D

func _ready() -> void:
	SimusNetConnection.connect_network_node_callables(self, _connect, _disconnect, func(): pass)

func _connect() -> void:
	if SimusNetConnection.is_server():
		$AnimationPlayer.speed_scale = SD_Random.get_rfloat_range(0.5, 2.0)
		$AnimationPlayer.play("idle")

func _disconnect() -> void:
	$AnimationPlayer.stop()
