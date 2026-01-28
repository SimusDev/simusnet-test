extends StaticBody3D

signal transfer_started
signal transfer_finished

@export var speed: float = 1.5
@export_group("References")
@export var inventory: CT_Inventory
@export var input_area: Area3D
@export var output_area: Area3D
@export var hand_node: Node3D

var _input_inventories: Array[CT_Inventory] = []
var _output_inventories: Array[CT_Inventory] = []
var _is_busy: bool = false

func _ready() -> void:
	if not SimusNetConnection.is_server():
		return
	
	if not inventory or \
		not input_area or \
		not output_area or \
		not hand_node:
		set_process(false)
		return

	input_area.body_entered.connect(func(b): _on_area_changed(b, _input_inventories, true))
	input_area.body_exited.connect(func(b): _on_area_changed(b, _input_inventories, false))
	output_area.body_entered.connect(func(b): _on_area_changed(b, _output_inventories, true))
	output_area.body_exited.connect(func(b): _on_area_changed(b, _output_inventories, false))

func _process(_delta: float) -> void:
	if _is_busy: return
	
	if inventory.get_item_stacks().is_empty():
		var provider = _get_active_inventory(_input_inventories)
		if provider and not provider.get_item_stacks().is_empty():
			var receiver = _get_active_inventory(_output_inventories)
			if receiver and not receiver.get_free_slots().is_empty():
				_drive_hand(provider.node.global_position, func(): _grab_item(provider))
	
	else:
		var receiver = _get_active_inventory(_output_inventories)
		if receiver and not receiver.get_free_slots().is_empty():
			_drive_hand(receiver.node.global_position, func(): _drop_item(receiver))

func _drive_hand(target_pos: Vector3, callback: Callable) -> void:
	_is_busy = true
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(hand_node, "global_position", target_pos, 1.0 / speed)
	tween.finished.connect(func():
		callback.call()
		_is_busy = false
	)

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
