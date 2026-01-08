extends SimusNetSingletonChild
class_name SimusNetTime

#signal on_tick()
#
#static var _instance: SimusNetTime
#
#var _timer: Timer
#
#static func get_instance() -> SimusNetTime:
	#return _instance
#
#func initialize() -> void:
	#SimusNetRPCGodot.register_authority_unreliable(
		#[_on_tick], SimusNetChannels.BUILTIN.TIME
	#)
	#_instance = self
	#process_mode = Node.PROCESS_MODE_DISABLED
	#SimusNetEvents.event_connected.listen(_on_connected)
	#SimusNetEvents.event_disconnected.listen(_on_disconnected)
#
#func _on_server_tick() -> void:
	#_timer.wait_time = 1.0 / singleton.settings.time_tickrate
	#SimusNetRPCGodot.invoke_all(_on_tick)
#
#func _on_tick() -> void:
	#on_tick.emit()
#
#func _on_connected() -> void:
	#if SimusNetConnection.is_was_server():
		#process_mode = Node.PROCESS_MODE_PAUSABLE
		#_timer = Timer.new()
		#_timer.timeout.connect(_on_server_tick)
		#add_child(_timer)
		#_timer.wait_time = 1.0 / singleton.settings.time_tickrate
		#_timer.start()
#
#func _on_disconnected() -> void:
	#if SimusNetConnection.is_was_server():
		#process_mode = Node.PROCESS_MODE_DISABLED
		#if is_instance_valid(_timer):
			#_timer.queue_free()
