class_name CT_DestroyOnDeath extends Node

@export_group("Custom References")
@export var health:CT_Health

func _ready() -> void:
	if not health and get_parent() is CT_Health:
		health = get_parent()
	
	if not health:
		return
	
	health.on_value_changed.connect(_on_health_value_changed)

func _on_health_value_changed():
	if health:
		if health.value <= 0:
			health.root.queue_free()
