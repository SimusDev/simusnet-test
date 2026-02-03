extends Button

var reference: R_WorldObject

func _ready() -> void:
	if !reference:
		return
	
	%Name.text = reference.id
	%Icon.texture = reference.get_icon()

func _pressed() -> void:
	if !reference:
		return
	
