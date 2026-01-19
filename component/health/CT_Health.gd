@icon("./icons/health.png")
extends Node
class_name CT_Health

signal on_value_changed()
signal on_value_max_changed()

@export var value: float = 100.0 : set = set_value
@export var value_max: float = 100.0 : set = set_value_max

func _ready() -> void:
	SimusNetNodeAutoVisible.register_or_get(self)
	SimusNetVars.register(self, [
		"value",
		"value_max"
	], SimusNetVarConfig.new().flag_mode_server_only().flag_replication())
	
	R_GameStateNodeReference.new(self).connect_events(
		func(e: R_GameStateNodeInstance):
			e.write(0, value)
			e.write(1, value_max)
			
			,
		func(e: R_GameStateNodeInstance):
			value = e.read(0)
			value_max = e.read(1)
	)

func set_value(new: float) -> CT_Health:
	value = clamp(value, 0.0, value_max)
	value = new
	on_value_changed.emit()
	return self

func set_value_max(new: float) -> CT_Health:
	value_max = new
	on_value_max_changed.emit()
	return self

func apply_damage(damage: R_Damage) -> CT_Health:
	damage.apply(self)
	return self

func kill() -> CT_Health:
	(
		R_Damage.new()
			.set_value(value_max)
			.apply(self)
	)
	return self
