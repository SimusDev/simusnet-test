@tool
extends RichTextLabel



func _init() -> void:
	add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
	add_theme_font_size_override(&"normal_font_size", 12)
	bbcode_enabled = true
	set_status("Idle")
	fit_content = true
	autowrap_mode = TextServer.AUTOWRAP_OFF
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


const WRITING := "[pulse]Writing[wave freq=5 amp=30]..."
const LOADING := "[pulse]Loading[wave freq=5 amp=30]..."
const THINKING := "[pulse]Thinking[wave freq=5 amp=30]..."
const IDLE := "Idle"

# This function is used to set the status of the RichTextLabel.

func set_status(status:String):
	match status:
		"Idle": text = IDLE
		"idle": text = IDLE
		"Loading": text = LOADING
		"loading": text = LOADING
		"Writing": text = WRITING
		"writing": text = WRITING
		"Thinking": text = THINKING
		"thinking": text = THINKING
		_: text = "[pulse]" + status + "[wave freq=5 amp=30]..."
