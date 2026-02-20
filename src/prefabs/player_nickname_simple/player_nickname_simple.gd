@tool
extends Node3D

@export var hide_if_authority:bool = true :
	set(val):
		hide_if_authority = val
		
		if Engine.is_editor_hint():
			return
		
		
		visible = !(is_multiplayer_authority() and hide_if_authority)
		set_process(visible)
		
		print(visible)

@onready var label_3d: Label3D = $Label3D

var _user: CT_User

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if is_multiplayer_authority() and hide_if_authority:
		visible = false
		set_process(false)
	
	_user = CT_User.find_by_peer(get_multiplayer_authority())
	if _user:
		_update()
		_user.on_nickname_changed.connect(_update)

func _update() -> void:
	label_3d.text = _user.get_nickname()

static func _get_camera() -> Camera3D:
	if SimusNetConnection.is_dedicated_server():
		return null
	
	#if OS.has_feature("editor"):
		#if Engine.is_editor_hint():
			#var viewport = EditorInterface.get_editor_viewport_3d(0)
			#return viewport.get_camera_3d()

	return SimusDev.get_viewport().get_camera_3d()

func _process(_delta: float) -> void:
	var camera: Camera3D = _get_camera()
		
	if not camera or not label_3d:
		return
	
	var distance = global_position.distance_to(camera.global_position)
	var max_dist = label_3d.visibility_range_end

	if max_dist <= 0:
		return

	var alpha = clamp(1.0 - (distance / max_dist), 0.0, 1.0)
	
	label_3d.modulate.a = alpha
