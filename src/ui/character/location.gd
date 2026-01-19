extends Button

var resource: R_LocationPoint

@export var COLOR_PRESSED: Color = Color(1.0, 1.0, 1.0)
@export var COLOR_NORMAL: Color = Color(1.0, 1.0, 1.0)

func _ready() -> void:
	$icon.texture = resource.level.icon
	$Label.text = resource.level.code + " : " + resource.name

func _process(delta: float) -> void:
	if button_pressed:
		modulate = lerp(modulate, COLOR_PRESSED, 25 * delta)
	else:
		modulate = lerp(modulate, COLOR_NORMAL, 25 * delta)
