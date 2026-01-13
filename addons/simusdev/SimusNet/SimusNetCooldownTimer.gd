extends RefCounted
class_name SimusNetCooldownTimer

var __is_active: bool = false
var __last_cooldown: float = 0.0

var __timer: SceneTreeTimer

func set_time(time: float) -> SimusNetCooldownTimer:
	__last_cooldown = time
	return self

func get_time() -> float:
	return __last_cooldown

func is_active() -> bool:
	return __is_active

func stop() -> SimusNetCooldownTimer:
	if __timer:
		if __timer.timeout.is_connected(__on_timeout):
			__timer.timeout.disconnect(__on_timeout)
	
	__timer = null
	__is_active = false
	return self

func start(time: float = 0.0) -> SimusNetCooldownTimer:
	if time > 0.0:
		__last_cooldown = time
	
	if is_active():
		stop()
	
	if __last_cooldown == 0.0:
		return self
	
	__timer = SimusDev.get_tree().create_timer(__last_cooldown, false)
	__timer.timeout.connect(__on_timeout)
	__is_active = true
	return self

func __on_timeout() -> void:
	stop()
