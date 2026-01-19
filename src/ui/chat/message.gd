extends SD_RichTextLabelSimple

var message: SimusNetChatMessage

func _ready() -> void:
	super()
	text = message.get_text()
	self_modulate = message.get_color()
	
