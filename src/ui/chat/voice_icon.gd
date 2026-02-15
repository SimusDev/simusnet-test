extends TextureRect

func _ready() -> void:
	visible = false
	
	var playable: CT_Playable = CT_Playable.get_local()
	if !playable:
		return
	
	visible = playable.get_voice_chat_status()
	
	playable.on_voice_chat_status_change.connect(_on_voice_chat_status_change)

func _on_voice_chat_status_change(new_status: bool) -> void:
	visible = new_status
