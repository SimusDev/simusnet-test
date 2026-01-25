extends Control

@onready var _custom: UI_BackpackCustom = UI_BackpackCustom.find_above(self)
@onready var ui_slot_control: UI_SlotControl = $UI_SlotControl

func _ready() -> void:
	$input_slots.set_inventory(_custom.get_inventory())
	$output_slots.set_inventory(_custom.get_inventory())
	$fuel_slots.set_inventory(_custom.get_inventory())
