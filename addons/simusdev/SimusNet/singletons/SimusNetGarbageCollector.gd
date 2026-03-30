extends SimusNetSingletonChild
class_name SimusNetGarbageCollector

@export var _timer: Timer
@export var wait_time: float = 10.0

var _thread: Thread = Thread.new()

func _ready() -> void:
	_timer.wait_time = wait_time
	SimusNetConnection.connect_network_node_callables(
		self,
		_on_network_ready,
		_on_network_disconnect,
		_on_network_not_connected,
	)
	

func collect() -> void:
	WorkerThreadPool.add_task(_collect_threaded)

func _collect_threaded() -> void:
	#print('trying to collect')
	
	var identites: Dictionary[int, SimusNetIdentity] = SimusNetIdentity.get_dictionary_by_unique_id()
	var identites_generated: Dictionary[Variant, SimusNetIdentity] = SimusNetIdentity.get_dictionary_by_generated_id()
	
	for i: int in identites:
		var identity: SimusNetIdentity = identites[i]
		if is_instance_valid(identity):
			if !is_instance_valid(identity.owner):
				identites.erase(i)
				
				while identity.get_reference_count() > 0:
					identity.unreference()
		else:
			identites.erase(i)
	
	for i: Variant in identites_generated:
		var identity: SimusNetIdentity = identites_generated[i]
		if is_instance_valid(identity):
			if !is_instance_valid(identity.owner):
				identites_generated.erase(i)
				
				while identity.get_reference_count() > 0:
					identity.unreference()
		else:
			identites_generated.erase(i)

func _exit_tree() -> void:
	if _thread.is_alive():
		_thread.wait_to_finish()

func _on_network_ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_timer.start()
	_timer.timeout.connect(_on_timeout)

func _on_network_disconnect() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	_timer.stop()
	_timer.timeout.disconnect(_on_timeout)

func _on_network_not_connected() -> void:
	pass

func _on_timeout() -> void:
	collect()
