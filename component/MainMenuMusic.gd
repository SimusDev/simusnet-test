@tool
class_name MainMenuMusic extends AudioStreamPlayer

@export var streams:Array[AudioStream]

@warning_ignore("unused_private_class_variable")
@export_tool_button("Play", "AudioStreamPlayer") var _play_btn = play_random

@export var play_at_ready:bool = true

func _ready() -> void:
	bus = "MainMenuMusic"
	if play_at_ready and not Engine.is_editor_hint():
		play_random()
	finished.connect(play_random)

func play_random() -> void:
	stream = streams.pick_random()
	play()
