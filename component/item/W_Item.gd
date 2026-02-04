class_name W_Item extends Node3D

signal event_pick
signal event_inspect

signal pressed
signal released

signal pressed_alt
signal released_alt

@export var object:R_WorldObject

var cooldown_timer:Timer 

var is_using:bool = false
var is_using_alt:bool = false

var net_config:SimusNetRPCConfig

var entity_head: CT_EntityHead

var entity:Entity = null
var entity_eyes:Node3D = null

var _logger: SD_Logger = SD_Logger.new(self)

var inventory: CT_Inventory
var stack: CT_ItemStack : get = _get_stack
var playable: CT_Playable
var state_machine: CT_StateMachineSimple

var _sounds: Dictionary[String, AudioStreamPlayer3D]

func _get_stack() -> CT_ItemStack:
	return stack

func _ready() -> void:
	SimusNetIdentity.register(self)
	
	stack = SD_ECS.find_first_component_by_script(self, [CT_ItemStack])
	
	inventory = SD_ECS.node_find_above_by_component(self, CT_Inventory)
	
	if !inventory:
		_logger.debug("INVENTORY COMPONENT WAS NOT FOUND!", SD_ConsoleCategories.ERROR)
		return
	
	#SimusNetVisible.set_visibile(self, SimusNetVisible.get_or_create(inventory))
	
	entity_head = CT_EntityHead.find_above(self)
	
	if !entity_head:
		_logger.debug("ENTITY HEAD COMPONENT WAS NOT FOUND!", SD_ConsoleCategories.ERROR)
		return
	
	entity = entity_head.get_entity()
	entity_eyes = entity_head.get_eyes()
	
	playable = CT_Playable.find_in(entity)
	
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
		
		if is_local() and SimusNetConnection.is_client():
			for client_prefab: PackedScene in object.clientside_prefabs:
				add_child(client_prefab.instantiate())
	
	
	
	state_machine = CT_StateMachineSimple.new()
	state_machine.on_transitioned.connect(_state_machine_transitioned)
	_state_machine_init()
	state_machine.name = "sm"
	state_machine.set_multiplayer_authority(get_multiplayer_authority())
	add_child(state_machine)
	
	event_pick.emit()
	
	if object is R_Item:
		if !object.pickup_sound.is_empty():
			_get_or_create_sound("pickup").stream = object.pickup_sound.pick_random()
			_get_or_create_sound("pickup").max_distance = 10
			_get_or_create_sound("pickup").play()
	
	set_process_input(is_local())
	set_process_unhandled_input(is_local())
	set_process_shortcut_input(is_local())
	set_process_unhandled_key_input(is_local())

func _get_or_create_sound(key: String) -> AudioStreamPlayer3D:
	if key in _sounds:
		return _sounds[key]
	
	var new: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	_sounds[key] = new
	add_child(new)
	return new

func _state_machine_init() -> void:
	pass

func _state_machine_transitioned(from: String, to: String) -> void:
	pass

func is_local() -> bool:
	return is_instance_valid(playable) and playable.is_local()

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
	
	_local_input(_event)

func _local_input(event: InputEvent) -> void:
	pass

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

func _pressed() -> void: pressed.emit()
func _released() -> void: released.emit()

func _pressed_alt() -> void: pressed_alt.emit()
func _released_alt() -> void: released_alt.emit()

func _local_client_ready() -> void:
	pass

func can_use() -> bool:
	if !is_local():
		return !in_cooldown()
	
	return (not in_cooldown()) and (SimusDev.ui.get_active_interfaces().is_empty())

func in_cooldown() -> bool:
	if not is_instance_valid(cooldown_timer):
		return true
	cooldown_timer.wait_time = (object as R_Item).use_cooldown
	return cooldown_timer.time_left > 0
