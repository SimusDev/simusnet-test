extends StaticBody3D

signal moved

@export var speed: float = 1.0
@export_group("References")
@export var inventory: CT_Inventory
@export var input_area: Area3D
@export var output_area: Area3D
@export var custom_target:Node3D

var target_node: Node3D
var is_moving: bool = false

func _ready() -> void:
	if not input_area or not output_area:
		set_process(false)
		return
	
	target_node = custom_target
	
	if not target_node:
		target_node = Node3D.new()
		add_child(target_node)
	
	var label = Label3D.new()
	label.text = "T"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

	target_node.add_child(label)
	
	for area in [input_area, output_area]:
		area.body_entered.connect(func(_b): _update_queues())
		area.body_exited.connect(func(_b): _update_queues())

func _process(_delta: float) -> void:
	if is_moving: return
	
	if not inventory.get_free_slots():
		return
	
	var provider = _get_first_valid_inventory(input_area)
	var receiver = _get_first_valid_inventory(output_area)
	
	if not provider:
		if receiver:
			if receiver != inventory:
				provider = inventory
	
	if provider:
		if provider.get_item_stacks().is_empty():
			return
	
	
		_start_transfer(provider, receiver)

func _start_transfer(from: CT_Inventory, to: CT_Inventory) -> void:
	is_moving = true
	moved.emit()
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(target_node, "global_position", from.node.global_position, speed)
	tween.tween_callback(func(): _perform_logic_transfer(from, inventory))
	
	if to:
		tween.tween_property(target_node, "global_position", to.node.global_position, speed)
	tween.finished.connect(
		func():
			is_moving = false
			_perform_logic_transfer(inventory, to)
			)

func _perform_logic_transfer(from: CT_Inventory, to: CT_Inventory) -> void:
	if not is_instance_valid(from) or not is_instance_valid(to):
		return
	
	if from.get_item_stacks().is_empty():
		return
	
	var item_stack = from.get_item_stacks().front()
	if not item_stack:
		return
	
	var input_slot:CT_InventorySlot = null

	print(to)
	#if to.get_slot_by_tag("input"):
		#input_slot = to.get_slot_by_tag("input")
	#else:
	if not to.get_item_stacks().is_empty():
		input_slot = to.get_free_slot_for(item_stack)
	
	if input_slot:
		if input_slot.is_free():
			from.try_remove_item(item_stack)
			to.try_add_item(item_stack)

func _get_first_valid_inventory(area: Area3D) -> CT_Inventory:
	for body in area.get_overlapping_bodies():
		var inv = CT_Inventory.find_in(body)
		if inv: return inv
	return null

func _update_queues() -> void:
	pass
