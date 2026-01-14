class_name MP_PlayerCanvasLayer extends CanvasLayer

@export var player:Player
@export var ui_prefab:PackedScene

func _ready() -> void:
	if not is_multiplayer_authority():
		return
	if not is_instance_valid(player):
		return
	
	if not player.is_node_ready():
		await player.ready
	
	var ui_instance:Node = ui_prefab.instantiate()
	add_child(ui_instance)
