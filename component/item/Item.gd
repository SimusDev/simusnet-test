#@icon("res://Games/source_game/components/icons/item.png")
#class_name SourceItem extends Node3D
#
#signal event_pick
#signal event_inspect
#
#@export var object:R_WorldObject
#@export var animation_library:AnimationLibrary
#
#var cooldown_timer:Timer 
#
#var network: SD_NetFunctionCaller
#
#var is_using:bool = false
#var is_using_alt:bool = false
#
#func _ready() -> void:
	#network = (SimusNetRPCConfig.new()
		##.
		##)
	##network.default_channel = "item"
	##add_child.call_deferred(network)
	#
	#if object is R_Item:
		#cooldown_timer = Timer.new()
		#cooldown_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
		#add_child(cooldown_timer)
		#cooldown_timer.wait_time = object.use_cooldown
		#cooldown_timer.one_shot = true
	#
	#set_process_input(SD_Network.is_authority(self))
	#
	#SD_Network.register_object(self)
	#SD_Network.register_functions(
		#[
			#__pressed_net,
			#__released_net,
			#__pressed_alt_net,
			#__released_alt_net,
		#]
	#)
	#
	#event_pick.emit()
	#
	##playable = SourcePlayable.find_above(self)
	##if playable:
		##player = playable.root
		##interact_ray = SD_Components.find_first(player, InteractRay)
		##animated_model = W_AnimatedModel3D.find_in(playable.root)
		##inventory = SD_Components.find_first(playable.root, CT_Inventory)
#
#static func find_above(node:Node) -> SourceItem:
	#if node is SourceItem or node == null:
		#return node
	#return find_above(node.get_parent())
#
#func _input(_event: InputEvent) -> void:
	#if SimusDev.ui.has_active_interface():
		#is_using = false
		#is_using_alt = false
		#return
	#
	#if Input.is_action_just_pressed("item.use"):
		#request_press()
	#elif Input.is_action_just_released("item.use"):
		#request_release()
	#elif Input.is_action_just_pressed("item.alt_use"):
		#request_press_alt()
	#elif Input.is_action_just_released("item.alt_use"):
		#request_release_alt()
	#elif Input.is_action_just_released("item.inspect"):
		#event_inspect.emit()
#
#func request_press() -> void:
	#network.call_func(__pressed_net)
#
#func request_release() -> void:
	#network.call_func(__released_net)
#
#func request_press_alt() -> void:
	#network.call_func(__pressed_alt_net)
#
#func request_release_alt() -> void:
	#network.call_func(__released_alt_net)
#
#func __pressed_net() -> void:
	#is_using = true
	#_pressed()
#
#func __released_net() -> void:
	#is_using = false
	#_released()
#
#func __pressed_alt_net() -> void:
	#is_using_alt = true
	#_pressed_alt()
#
#func __released_alt_net() -> void:
	#is_using_alt = false
	#_released_alt()
#
#func _pressed() -> void: pass
#func _released() -> void: pass
#
#func _pressed_alt() -> void: pass
#func _released_alt() -> void: pass
#
#
#func can_use() -> bool:
	#return (not in_cooldown()) and (SimusDev.ui.get_active_interfaces().is_empty())
#
#func in_cooldown() -> bool:
	#return cooldown_timer.time_left > 0
