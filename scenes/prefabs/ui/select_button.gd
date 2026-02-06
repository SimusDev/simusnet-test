extends Button

var is_current:bool = false :
	set(val):
		is_current = val
		$ReferenceRect.visible = val

func _ready() -> void:
	$ReferenceRect.visible = is_current

func _on_button_down() -> void:
	scale = Vector2(.98, .98)


func _on_button_up() -> void:
	scale = Vector2(1.0, 1.0)
