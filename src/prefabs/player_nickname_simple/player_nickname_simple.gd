@tool
extends Node3D

@onready var label_3d: Label3D = $Label3D

var _user: CT_User

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_user = CT_User.find_by_peer(get_multiplayer_authority())
	if _user:
		_update()
		_user.on_nickname_changed.connect(_update)

func _update() -> void:
	label_3d.text = _user.get_nickname()

func _process(_delta: float) -> void:
	var camera: Camera3D
	
	if Engine.is_editor_hint():
		camera = EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	else:
		camera = get_tree().root.get_camera_3d()
		
	if not camera or not label_3d:
		return
	
	var distance = global_position.distance_to(camera.global_position)
	var max_dist = label_3d.visibility_range_end

	if max_dist <= 0:
		return

	var alpha = clamp(1.0 - (distance / max_dist), 0.0, 1.0)
	
	label_3d.modulate.a = alpha
