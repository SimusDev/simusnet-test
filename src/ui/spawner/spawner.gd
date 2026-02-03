extends Control

@onready var inventory_checkbox: CheckButton = %InventoryCheckbox
@onready var quantity_line_edit: LineEdit = %QuantityLineEdit
@onready var tree: Tree = %Tree

@export var _object_container: Control
@export var _object_ui: PackedScene

var _objects: Dictionary[String, Array] = {}

func _ready() -> void:
	await SD_Nodes.async_clear_all_children(_object_container)
	for object in R_WorldObject.get_world_object_list():
		_cache_object(object)

func _cache_object(object: R_WorldObject) -> void:
	if !object.is_spawnable():
		return
	
	var group: String = object.get_group()
	if !_objects.has(group):
		var item: TreeItem = tree.create_item()
		item.set_text(0, group)
	
	var array: Array[R_WorldObject] = _objects.get_or_add(group, [] as Array[R_WorldObject])
	if array.has(object):
		return
	
	array.append(object)

func _on_tree_item_selected() -> void:
	var array: Array[R_WorldObject] = _objects.get_or_add(tree.get_selected().get_text(0), [] as Array[R_WorldObject])
	await SD_Nodes.async_clear_all_children(_object_container)
	for i in array:
		var ui: Button = _object_ui.instantiate()
		ui.reference = i
		ui.pressed.connect(_on_object_selected.bind(i))
		_object_container.add_child(ui)

func _on_object_selected(object: R_WorldObject) -> void:
	var quantity: int = quantity_line_edit.text.to_int()
	if quantity < 1:
		quantity = 1
	SpawnableObjects.request_spawn_from_camera(object, quantity, inventory_checkbox.button_pressed)
