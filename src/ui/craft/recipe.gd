extends Button

var resource: R_Recipe

func _ready() -> void:
	if !resource:
		return
	
	icon = resource.output.get_icon()
	text = resource.output.id + (" (x%s) " % resource.output_quantity)
	
