extends Control

@onready var _custom: UI_BackpackCustom = UI_BackpackCustom.find_above(self)

func _ready() -> void:
	$input.set_inventory(_custom.get_inventory())
	$output.set_inventory(_custom.get_inventory())
