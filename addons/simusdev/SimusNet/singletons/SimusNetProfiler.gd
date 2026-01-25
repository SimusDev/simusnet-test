extends SimusNetSingletonChild
class_name SimusNetProfiler

static var _instance: SimusNetProfiler

var _up_packets: int = 0
var _down_packets: int = 0

var _total_traffic: int = 0

var _up_traffic: int = 0
var _down_traffic: int = 0

var _transform_up_traffic: int = 0
var _transform_down_traffic: int = 0

var _ping: int = 0

var _timer: Timer
var _timer_tickrate: float = 1.0

var _rpcs_profiler: Dictionary[String, Dictionary] = {}
var _vars_profiler: Dictionary[Dictionary, Dictionary] = {}
var _transform_profiler: Dictionary[Dictionary, Dictionary] = {}

signal on_rpc_profiler_add(key: String, data: Dictionary)
signal on_rpc_profiler_change(key: String)

func _ready() -> void:
	_instance = self

func initialize() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	
	SimusNetEvents.event_connected.listen(_on_connected)
	SimusNetEvents.event_disconnected.listen(_on_disconnected)

func _on_connected() -> void:
	if is_instance_valid(_timer):
		return
	
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	_timer = Timer.new()
	_timer.autostart = true
	_timer.wait_time = _timer_tickrate
	_timer.one_shot = false
	_timer.timeout.connect(_timer_tick)
	add_child(_timer)
	_timer.start()

func _on_disconnected() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	
	if is_instance_valid(_timer):
		_timer.stop()
		_timer.queue_free()
		_timer = null

func _put_total_traffic(size: int) -> void:
	_total_traffic += size

func _put_up_traffic(size: int) -> void:
	_up_traffic += size
	_put_total_traffic(size)

func _put_down_traffic(size: int) -> void:
	_down_traffic += size
	_put_total_traffic(size)

static func _put_up_packet() -> void:
	_instance._up_packets += 1

static func _put_down_packet() -> void:
	_instance._down_packets += 1

func _put_rpc_traffic(size: int, identity: Variant, method: Variant, receive: bool) -> void:
	#var identity_name: String = str(identity)
	#if identity is SimusNetIdentity:
		#if is_instance_valid(identity.owner):
			#var obj_script: Variant = identity.owner.get_script()
			#if obj_script is Script:
				#identity_name = obj_script.get_global_name()
			#else:
				#identity_name = identity.get_generated_unique_id()
			#
			#identity_name += "(ID: %s)" % identity.get_unique_id()
			 #
	#
	var method_name: String = str(method)
	
	var key: String = method_name
	var emit: bool = !_rpcs_profiler.has(key)
	var data: Dictionary = _rpcs_profiler.get_or_add(key, {})
	
	var down_traffic: int = data.get_or_add("down", 0)
	var up_traffic: int = data.get_or_add("up", 0)
	
	var down_calls: int = data.get_or_add("down_calls", 0)
	var up_calls: int = data.get_or_add("up_calls", 0)
	
	if receive:
		down_calls += 1
		down_traffic += size
	else:
		up_calls += 1
		up_traffic += size
	
	data.down = down_traffic
	data.up = up_traffic
	data.down_calls = down_calls
	data.up_calls = up_calls
	
	on_rpc_profiler_change.emit(key)
	
	if emit:
		on_rpc_profiler_add.emit(key, data)

func _timer_tick() -> void:
	_up_packets /= 2
	_down_packets /= 2
	_down_traffic /= 2
	_up_traffic /= 2
	_transform_down_traffic /= 2
	_transform_up_traffic /= 2

static func get_instance() -> SimusNetProfiler:
	return _instance

static func get_total_traffic() -> int:
	return _instance._total_traffic

static func get_up_traffic_per_second() -> int:
	return _instance._up_traffic

static func get_down_traffic_per_second() -> int:
	return _instance._down_traffic

static func get_transform_up_traffic_per_second() -> int:
	return _instance._transform_up_traffic

static func get_transform_down_traffic_per_second() -> int:
	return _instance._transform_down_traffic

static func get_up_packets_count() -> int:
	return _instance._up_packets

static func get_down_packets_count() -> int:
	return _instance._down_packets

static func send_ping_request_to_server() -> void:
	var timestamp_ms: int = Time.get_ticks_msec()
	_instance._receive_ping_request.rpc_id(SimusNet.SERVER_ID, timestamp_ms)

static func get_ping() -> int:
	return _instance._ping

@rpc("any_peer", "call_local", "unreliable", SimusNetChannels.BUILTIN.TIME)
func _receive_ping_request(request_timestamp_ms: int):
	var current_time: int = Time.get_ticks_msec()
	_receive_ping_response.rpc_id(multiplayer.get_remote_sender_id(), current_time - request_timestamp_ms)

@rpc("any_peer", "call_local", "unreliable", SimusNetChannels.BUILTIN.TIME)
func _receive_ping_response(ping: int):
	_ping = ping
