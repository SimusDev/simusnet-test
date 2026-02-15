@icon("res://component/icons/health.png")
extends Node
class_name CT_Health

@export var root: Node


signal on_value_changed()
signal on_value_max_changed()

@export var value: float = 100.0 : set = set_value
@export var value_max: float = 100.0 : set = set_value_max

@export_group("UI")
@export var ui_prefab:PackedScene

func _ready() -> void:
	set_multiplayer_authority(SimusNet.SERVER_ID)
	if root.is_multiplayer_authority() and ui_prefab:
		if root is Entity:
			var ui = ui_prefab.instantiate()
			ui.entity = root
			ui.health = self
			add_child(ui)
	
	SD_ECS.append_to(root, self)
	
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

static func find_above(node:Node3D) -> CT_Health:
	return null

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
