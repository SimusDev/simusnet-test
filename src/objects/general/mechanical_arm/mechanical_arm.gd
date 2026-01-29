extends StaticBody3D

signal transfer_started
signal transfer_finished

@export var speed: float = 0.5
@export_group("References")
@export var inventory: CT_Inventory
@export var input_area: Area3D
@export var output_area: Area3D
@export var hand_node: Node3D
@export var home_node: Node3D # <-- НОВЫЙ: узел, определяющий позицию "покоя"

var _input_inventories: Array[CT_Inventory] = []
var _output_inventories: Array[CT_Inventory] = []
var _is_busy: bool = false
var _active_tween: Tween # <-- НОВЫЙ: ссылка на активный твин для управления им

func _ready() -> void:
	if not inventory or not input_area or not output_area or not hand_node or not home_node:
		set_process(false)
		return

	if not SimusNetConnection.is_server():
		set_process(false) # Клиенты только реплицируют свойства
		return
		
	input_area.body_entered.connect(func(b): _on_area_changed(b, _input_inventories, true))
	input_area.body_exited.connect(func(b): _on_area_changed(b, _input_inventories, false))
	output_area.body_entered.connect(func(b): _on_area_changed(b, _output_inventories, true))
	output_area.body_exited.connect(func(b): _on_area_changed(b, _output_inventories, false))

func _process(_delta: float) -> void:
	if _is_busy: return
	
	var provider = _get_active_inventory(_input_inventories)
	var receiver = _get_active_inventory(_output_inventories)
	var has_item_in_hand = not inventory.get_item_stacks().is_empty()

	# 1. Если в руке предмет -> пытаемся отдать или возвращаемся домой
	if has_item_in_hand:
		if receiver and not receiver.get_free_slots().is_empty():
			_drive_hand(receiver.node.global_position, func(): 
				_drop_item(receiver)
				# После отдачи сразу идем домой
				_drive_hand(home_node.global_position) 
			)
		# Если отдать не можем, просто возвращаемся домой
		elif hand_node.global_position != home_node.global_position:
			_drive_hand(home_node.global_position)

	# 2. Если рука пуста -> пытаемся взять
	else:
		if provider and not provider.get_item_stacks().is_empty():
			# Убеждаемся, что есть куда класть, прежде чем брать
			if receiver and not receiver.get_free_slots().is_empty():
				_drive_hand(provider.node.global_position, func(): 
					_grab_item(provider)
					# После захвата *сразу* идем домой (следующее _process отправит его к приемнику)
					_drive_hand(home_node.global_position)
				)
		# Если взять нечего, просто возвращаемся домой
		elif hand_node.global_position != home_node.global_position:
			_drive_hand(home_node.global_position)

func _drive_hand(target_pos: Vector3, callback: Callable = Callable(_do_nothing)) -> void:
	# Останавливаем предыдущий твин, если он еще активен
	if _active_tween and is_instance_valid(_active_tween):
		_active_tween.kill()

	_is_busy = true
	_active_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tween.tween_property(hand_node, "global_position", target_pos, 1.0 / speed)
	
	_active_tween.finished.connect(func():
		callback.call()
		_is_busy = false
		call_deferred("_process", 0.0) 
	)

func _do_nothing() -> void:
	pass

func _grab_item(from: CT_Inventory) -> void:
	var stacks = from.get_item_stacks()
	if stacks.is_empty(): return
	
	var item = stacks.front()
	if inventory.try_add_item(item):
		from.try_remove_item(item)
		transfer_started.emit()

func _drop_item(to: CT_Inventory) -> void:
	var stacks = inventory.get_item_stacks()
	if stacks.is_empty(): return
	
	var item = stacks.front()
	if to.try_add_item(item):
		inventory.try_remove_item(item)
		transfer_finished.emit()

func _on_area_changed(body: Node3D, list: Array[CT_Inventory], added: bool) -> void:
	var inv = CT_Inventory.find_in(body)
	if not inv: return
	if added:
		if not list.has(inv): list.append(inv)
	else:
		list.erase(inv)

func _get_active_inventory(list: Array[CT_Inventory]) -> CT_Inventory:
	for inv in list:
		if is_instance_valid(inv): return inv
	return null
