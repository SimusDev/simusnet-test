extends RigidBody3D

func _ready() -> void:
	_update()
	$CT_Furnace.active_change.connect(_update)

func _update() -> void:
	$CPUParticles3D.emitting = $CT_Furnace.is_active()
	$OmniLight3D.visible = $CT_Furnace.is_active()
