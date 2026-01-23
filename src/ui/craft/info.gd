extends Button

var data: R_RecipeData

func _ready() -> void:
	if !data:
		return
	
	text = data.object.id + (" (x%s)" % data.quantity)
	icon = data.object.get_icon()
