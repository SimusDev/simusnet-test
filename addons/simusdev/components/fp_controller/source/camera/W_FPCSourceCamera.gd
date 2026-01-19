extends W_FPCSource
class_name W_FPCSourceCamera


@export var body: CharacterBody3D
@export var camera: Camera3D
@export var camera_angle_min: float = -90
@export var camera_angle_max: float = 90

@export_group("Sensitivity")
@export var configurable_sensitivity: bool = true
@export var sensitivity: float = 1.0

@export_group("Free Camera")
@export var freecam_speed: float = 10.0
@export var freecam_boost_scale: float = 3.0
@export var freecam_slowdown_scale: float = 0.3
@export var key_forward: String = "ui_up"
@export var key_backward: String = "ui_down"
@export var key_left: String = "ui_left"
@export var key_right: String = "ui_right"
@export var key_boost: String = "boost"
@export var key_slowdown: String = "slowdown"

@onready var _console: SD_TrunkConsole = SimusDev.console

static var _cameras: Array[W_FPCSourceCamera] = []

func _enter_tree() -> void:
	_cameras.append(self)

func _exit_tree() -> void:
	_cameras.erase(self)

func _ready() -> void:
	super()
	

func _process(delta: float) -> void:
	_handle_free_camera(delta)

func _handle_free_camera(delta: float) -> void:
	if _console.is_visible():
		return
	
	var input_dir: Vector2 = Input.get_vector(key_left, key_right, key_forward, key_backward)
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var velocity: Vector3 = direction
	velocity *= freecam_speed
	
	if Input.is_action_pressed(key_boost):
		velocity *= freecam_boost_scale
	if Input.is_action_pressed(key_slowdown):
		velocity *= freecam_slowdown_scale
	
	global_translate(velocity * delta)

func _active_status_changed() -> void:
	if enabled:
		_process_other_cameras()
		camera.make_current()
		process_mode = Node.PROCESS_MODE_INHERIT
		SimusDev.cursor.set_mode(SD_TrunkCursor.MODE_CAPTURED)
	else:
		camera.clear_current()
		process_mode = Node.PROCESS_MODE_DISABLED
		SimusDev.cursor.set_mode(SD_TrunkCursor.MODE_VISIBLE)

func _process_other_cameras() -> void:
	for i in _cameras:
		if i == self:
			continue
		
		i.enabled = false

func is_can_free_move() -> bool:
	return (not body) and camera.current

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	if event is InputEventMouseMotion:
		var sens: float = sensitivity * 0.1
		var relative: Vector2 = event.relative
		
		var y: float = deg_to_rad(-relative.x * sens)
		var x: float = deg_to_rad(-relative.y * sens)
		
		if body:
			body.rotate_y(y)
			rotate_x(x)
			rotation.x = clamp(rotation.x, deg_to_rad(camera_angle_min), deg_to_rad(camera_angle_max))
		else:
			if is_can_free_move():
				rotate_y(y)
				var pitch: float = x
				rotate_object_local(Vector3(1, 0, 0), pitch)
