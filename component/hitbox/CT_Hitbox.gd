class_name CT_Hitbox extends Area3D

@export var damage_multiplier:float = 1.0

@export var health:CT_Health

func _ready() -> void:
	SD_Components.append_to(Player.get_local(), self)

#ONLY SERVER LOGIC
func apply_damage(points:float) -> void:
	if not is_instance_valid(health):
		SimusDev.console.write_error("'%s' health_component is null" % [self])
		return
	(
	R_Damage.new()
		.set_source(Player.get_local())
		.set_value(points * damage_multiplier)
		.apply(health)
	)
