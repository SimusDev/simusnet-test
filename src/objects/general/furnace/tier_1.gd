extends RigidBody3D

func _ready() -> void:
	$CPUParticles3D.emitting = $CT_Furnace.is_active()
	$CT_Furnace.active_change.connect(
		func():
			$CPUParticles3D.emitting = $CT_Furnace.is_active()
			)
