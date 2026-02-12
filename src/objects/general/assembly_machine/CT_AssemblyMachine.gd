class_name CT_AssemblyMachine extends Node

signal active_change
signal recipe_change

@export var root: Node
@export var ct_tick:CT_Tick
@export var input_slots: int = 6

@export var _inventory: CT_Inventory
@export var _progress:float = 0.0

var active:bool = false :
	set(val):
		active = val
		active_change.emit()
		


var recipe:R_Recipe :
	set(val):
		recipe = val
		recipe_change.emit()
		

func _ready() -> void:
	ct_tick.tick.connect(_on_tick)

func _on_tick() -> void:
	pass
