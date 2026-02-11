extends Panel

@export var chat: SimusNetChat
@export var text_label: RichTextLabel
@export var hide_delay:float = 5.0
@export var hide_duration:float = 1.0

var tween:Tween

func _ready() -> void:
	if not is_multiplayer_authority():
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	if not chat:
		return
	
	tween = create_tween()
	
	chat.on_message_received.connect(_on_message_received)
	s_Users.on_connected.connect(_on_user_connected)

func _on_user_connected(user:CT_User) -> void:
	_add_message("[color=orange]%s connected[/color]" % [user.get_nickname()])

func _on_message_received(msg: SimusNetChatMessage) -> void:
	if not text_label:
		return
	
	_add_message(_get_message_text(msg))

func _add_message(text:String):
	text_label.text += text + "\n"
	
	if tween:
		tween.kill() 
	
	modulate.a = 1.0
	
	tween = create_tween()
	
	tween.tween_interval(hide_delay)
	tween.tween_property(self, "modulate:a", 0.0, hide_duration)

func _get_message_text(msg: SimusNetChatMessage) -> String:
	var user:CT_User = CT_User.find_by_peer(msg.get_peer_id())
	if not user:
		return ""
	return "%s: %s" % [
		user.get_nickname(),
		msg.get_text()
		]
