extends Node3D

var _user: CT_User

@onready var nick: Label = %Nick
@onready var avatar: TextureRect = %Avatar

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_user = CT_User.find_by_peer(get_multiplayer_authority())
	if _user:
		_update()
		_user.on_avatar_changed.connect(_update)
		_user.on_nickname_changed.connect(_update)
	

func _update() -> void:
	nick.text = _user.get_nickname()
	avatar.texture = _user.get_avatar()
