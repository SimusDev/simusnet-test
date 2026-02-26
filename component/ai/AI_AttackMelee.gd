class_name AI_AttackMelee extends Node

signal on_impact

@export var entity_ai:EntityAI
@export var ct_cooldown:CT_CoolDown

@export var impact_delay:float = 0.0
@export var attack_range:float = 2.5
@export var state_idle:StringName = "Idle"
@export var state_attack:StringName = "Attack"


func _ready() -> void:
	entity_ai.ct_tick.tick.connect(_on_tick)

func _on_tick() -> void:
	if ct_cooldown.in_cooldown():
		return
	
	var target = entity_ai.ai_targeting.target
	if not target:
		return
	
	if entity_ai.root.global_position.distance_to(target.global_position) < attack_range:
		attack()
		ct_cooldown.start()

func attack() -> void:
	entity_ai.state_machine.try_switch(state_attack)
	
	await get_tree().create_timer(impact_delay).timeout
	
	entity_ai.state_machine.try_switch(state_idle)
	on_impact.emit()
