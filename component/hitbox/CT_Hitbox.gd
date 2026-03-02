@tool
class_name CT_Hitbox extends Area3D

@export var damage_multiplier:float = 1.0
@export var health:CT_Health


func _init() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true)
	set_collision_mask_value(3, true)

func _ready() -> void:
	pass

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
