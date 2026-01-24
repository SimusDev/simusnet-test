extends Node
class_name CT_HotbarInput

@export var root: Node
@export var inventory: CT_Inventory

func _ready() -> void:
	if !root:
		root = get_parent()
	
	if !root.is_node_ready():
		await root.ready
	
	if !inventory:
		inventory = CT_Inventory.find_in(root)
	
	CT_LocalInput.get_or_create(root).on_input.connect(_on_input)

func _on_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key: String = event.as_text_key_label()
		if key.is_valid_int():
			inventory.request_slot_select_by_id(key.to_int() - 1)
