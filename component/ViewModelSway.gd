class_name ViewModelSway extends Node

var view_model: Node3D
var mouse_input:Vector2

func _ready():
	var auth:bool = SD_Network.is_authority(self)
	set_process(auth)
	set_process_input(auth)
	if auth:
		view_model = get_parent()

func _unhandled_input(event):
	if SimusDev.ui.has_active_interface():
		return
	if event is InputEventMouseMotion:
		mouse_input += event.relative * 0.00075

func _physics_process(delta: float) -> void:
	if not view_model:
		return
	
	var target_pos = Vector3(mouse_input.x, -mouse_input.y, 0)
	var target_rot = Vector3(mouse_input.y, mouse_input.x, 0) * 1.5
	
	var weight = 1.0 - exp(-10 * delta)
	var mouse_decay = 1.0 - exp(-20.0 * delta)
	
	
	view_model.position = view_model.position.lerp(target_pos, weight)
	
	view_model.rotation.x = lerp_angle(view_model.rotation.x, target_rot.x, weight)
	view_model.rotation.y = lerp_angle(view_model.rotation.y, target_rot.y, weight)
	
	mouse_input = mouse_input.lerp(Vector2.ZERO, 1.0 - mouse_decay)
