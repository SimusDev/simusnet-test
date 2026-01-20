extends Control

@onready var _custom: UI_BackpackCustom = UI_BackpackCustom.find_above(self)
@onready var ui_slot_control: UI_SlotControl = $UI_SlotControl

func _ready() -> void:
	ui_slot_control.inventory = _custom.get_inventory()
