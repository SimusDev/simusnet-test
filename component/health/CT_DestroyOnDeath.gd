class_name CT_DestroyOnDeath extends Node

@export_group("Custom References")
@export var health:CT_Health

func _ready() -> void:
	var rpc_cfg:SimusNetRPCConfig = SimusNetRPCConfig.new()
	rpc_cfg.flag_mode_any_peer()
	
	SimusNetRPC.register(
		[
			_destroy_net
		],
		rpc_cfg
	)
	
	if not multiplayer.is_server():
		return
	
	if not health and get_parent() is CT_Health:
		health = get_parent()
	
	if not health:
		return
	
	health.on_value_changed.connect(_on_health_value_changed)

func _on_health_value_changed():
	if health:
		if health.value <= 0:
			SimusNetRPC.invoke_all(_destroy_net, health)

func _destroy_net(target_health:CT_Health) -> void:
	if is_instance_valid(target_health.root):
		target_health.root.queue_free()
