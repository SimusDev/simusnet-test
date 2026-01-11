extends W_FPCSource
class_name W_FPCSourceMovement

@export var actor: CharacterBody3D

func _ready() -> void:
	super()
	

func _active_status_changed() -> void:
	if enabled:
		process_mode = Node.PROCESS_MODE_INHERIT
	else:
		process_mode = Node.PROCESS_MODE_DISABLED

func _multiplayer_authority_changed() -> void:
	enabled = SimusNet.is_network_authority(self)
