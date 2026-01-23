extends Node
class_name CT_IControlInterface

@export var target: Control

func _ready() -> void:
	if !target:
		target = get_parent()
	
	if !target.is_node_ready():
		await target.ready
	
	if target.is_visible_in_tree():
		SimusDev.ui.open_interface(self)
	
	target.draw.connect(_on_draw)
	target.hidden.connect(_on_hidden)

func _on_draw() -> void:
	SimusDev.ui.open_interface(self)

func _on_hidden() -> void:
	SimusDev.ui.close_interface(self)
