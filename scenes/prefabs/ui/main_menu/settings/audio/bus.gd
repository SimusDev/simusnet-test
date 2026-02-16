extends Panel

var bus: SD_AudioBus

@onready var name_label: Label = $Name
@onready var h_slider: HSlider = $HSlider

func _ready() -> void:
	_update_percents()
	h_slider.value = bus.get_volume()

func _update_percents() -> void:
	name_label.text = bus.get_name() + " - " + str(round(bus.get_volume() * 100.0)) + "%"

#func _on_h_slider_drag_ended(value_changed: bool) -> void:
	#if value_changed:
		#bus.set_volume(h_slider.value)
		#_update_percents()

func _on_h_slider_value_changed(value: float) -> void:
	bus.set_volume(value)
	_update_percents()
