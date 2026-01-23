extends Control

@onready var _custom: UI_BackpackCustom = UI_BackpackCustom.find_above(self)

@onready var _crafting: CraftingTable

func _ready() -> void:
	_crafting = _custom.get_inventory().node
	$input.set_inventory(_custom.get_inventory())
	$output.set_inventory(_custom.get_inventory())

func _on_craft_pressed() -> void:
	print(_crafting)
