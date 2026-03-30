extends Node
class_name SD_UICanvasItemInterface

@export var targets: Array[CanvasItem] = []

signal on_item_draw(item: CanvasItem)
signal on_item_hidden(item: CanvasItem)

func _ready() -> void:
	for i in targets:
		if !is_instance_valid(i):
			continue
		
		if !i.is_node_ready():
			await i.ready
		
		if i.is_visible_in_tree():
			_on_item_draw(i)
		else:
			_on_item_hidden(i)
		
		i.draw.connect(_on_item_draw.bind(i))
		i.hidden.connect(_on_item_hidden.bind(i))

func _exit_tree() -> void:
	for i in targets:
		if is_instance_valid(i):
			_on_item_hidden(i)

func _on_item_draw(item: CanvasItem) -> void:
	SimusDev.ui.open_interface(item)
	on_item_draw.emit(item)

func _on_item_hidden(item: CanvasItem) -> void:
	SimusDev.ui.close_interface(item)
	on_item_hidden.emit(item)
