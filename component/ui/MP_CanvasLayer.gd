class_name MP_PlayerCanvasLayer extends CanvasLayer

@export var ui_prefab:PackedScene

func _ready() -> void:
	if not is_multiplayer_authority():
		return
	
	var ui_instance:Node = ui_prefab.instantiate()
	add_child(ui_instance)
