extends SimusNetChat

@export var active_chat:Control
@export var chat_view:Control


func _ready() -> void:
	super()
	if is_multiplayer_authority():
		active_chat.visibility_changed.connect(_on_active_chat_visiblity_changed)
	SimusNetEvents.event_connected.listen(_on_connected)

func _on_active_chat_visiblity_changed() -> void:
	chat_view.modulate.a = 1.0

func _on_connected() -> void:
	if SimusNetConnection.is_dedicated_server():
		if is_instance_valid(active_chat):
			active_chat.queue_free()
		if is_instance_valid(chat_view):
			chat_view.queue_free()
		SimusNetEvents.event_connected.unlisten(_on_connected)

func server_message_received(message: SimusNetChatMessage) -> SimusNetChatMessage:
	return message

func client_message_received(message: SimusNetChatMessage) -> SimusNetChatMessage:
	return message
