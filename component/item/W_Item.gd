class_name W_Item extends Node3D

signal event_pick
signal event_inspect

var player:Player
var player_camera:W_FPCSourceLikeCamera
@export var object:R_WorldObject

var cooldown_timer:Timer 

var is_using:bool = false
var is_using_alt:bool = false

var net_config:SimusNetRPCConfig

func _ready() -> void:
	net_config = (SimusNetRPCConfig.new()
		.flag_set_channel("item")
		.flag_mode_any_peer()
		)
	
	SimusNetRPC.register(
		[
			__pressed_net,
			__released_net,
			__pressed_alt_net,
			__released_alt_net,
		],
		net_config
	)
	
	if not object:
		object = R_WorldObject.find_in(self)
	
	if object is R_Item:
		cooldown_timer = Timer.new()
		cooldown_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
		add_child(cooldown_timer)
		cooldown_timer.wait_time = object.use_cooldown
		cooldown_timer.one_shot = true
	
	set_process_input(SimusNet.is_network_authority(self))
	
	event_pick.emit()

static func find_above(node:Node) -> W_Item:
	if node is W_Item or node == null:
		return node
	return find_above(node.get_parent())

func _input(_event: InputEvent) -> void:
	if SimusDev.ui.has_active_interface():
		is_using = false
		is_using_alt = false
		return
	
	if Input.is_action_just_pressed("item.use"):
		request_press()
	elif Input.is_action_just_released("item.use"):
		request_release()
	elif Input.is_action_just_pressed("item.alt_use"):
		request_press_alt()
	elif Input.is_action_just_released("item.alt_use"):
		request_release_alt()
	elif Input.is_action_just_released("item.inspect"):
		event_inspect.emit()

func request_press() -> void:
	SimusNetRPC.invoke_all(__pressed_net)

func request_release() -> void:
	SimusNetRPC.invoke_all(__released_net)

func request_press_alt() -> void:
	SimusNetRPC.invoke_all(__pressed_alt_net)

func request_release_alt() -> void:
	SimusNetRPC.invoke_all(__released_alt_net)

func __pressed_net() -> void:
	is_using = true
	_pressed()

func __released_net() -> void:
	is_using = false
	_released()

func __pressed_alt_net() -> void:
	is_using_alt = true
	_pressed_alt()

func __released_alt_net() -> void:
	is_using_alt = false
	_released_alt()

func _pressed() -> void: pass
func _released() -> void: pass

func _pressed_alt() -> void: pass
func _released_alt() -> void: pass

func can_use() -> bool:
	return (not in_cooldown()) and (SimusDev.ui.get_active_interfaces().is_empty())

func in_cooldown() -> bool:
	if not is_instance_valid(cooldown_timer):
		return true
	return cooldown_timer.time_left > 0
