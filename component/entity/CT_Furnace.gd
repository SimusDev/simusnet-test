extends Node
class_name CT_Furnace

@export var root: Node3D
@export var tickrate: float = 20.0
#@export var fuel_consumption: float = 1.0
@export var slots: int = 1

@export var _inventory: CT_Inventory
@export var _audio_player: AudioStreamPlayer3D

@export var _fuel_ticks: int = 0 : set = set_fuel_ticks
@export var _progress: int = 0
@export var _progress_max: int = 100

var _is_active: bool = false : set = set_active

var _timer: Timer

var _server_bake_slots: Dictionary[CT_InventorySlot, CT_InventorySlot] = {}
var _server_fuel_slots: Array[CT_InventorySlot] = []

const FUEL_OBJECTS: Array[String] = [
	"fuel",
	"wooden",
]

func is_active() -> bool:
	return _is_active

func set_fuel_ticks(ticks: int) -> CT_Furnace:
	_fuel_ticks = ticks
	set_active(_fuel_ticks > 0)
	return self

func set_active(value: bool) -> void:
	if _is_active == value:
		return
	
	_is_active = value
	
	await SD_Nodes.async_for_ready(self)
	if _is_active:
		_audio_player.play()
	else:
		_audio_player.stop()

func get_inventory() -> CT_Inventory:
	return _inventory

func _network_setup() -> void:
	SimusNetVars.register(self, [
		"_is_active",
		
	], SimusNetVarConfig.new().flag_tickrate(20)
	.flag_mode_server_only()
	.flag_replication()
	)
	
	
	

func _ready() -> void:
	if !root:
		root = get_parent()
	
	_network_setup()
	
	R_InteractAction.ACTION_OPEN.append_to(root)
	
	await SD_Nodes.async_for_ready(root)
	
	if SimusNetConnection.is_server():
		var fuel_slot: CT_InventorySlot = _inventory.add_slot_by_script(CT_InventorySlot)
		fuel_slot.tags.set("fuel", true)
		_server_fuel_slots.append(fuel_slot)
		
		for slot_id in slots:
			var input: CT_InventorySlot = _inventory.add_slot_by_script(CT_InventorySlot)
			var output: CT_InventorySlot = _inventory.add_slot_by_script(CT_InventorySlot)
			input.tags.set("input", true)
			output.tags.set("output", true)
			_server_bake_slots[input] = output
		
		_timer = Timer.new()
		_timer.wait_time = 1.0 / tickrate
		_timer.autostart = true
		_timer.timeout.connect(_on_server_tick)
		add_child(_timer)

func _on_server_tick() -> void:
	_timer.wait_time = 1.0 / tickrate
	
	if _fuel_ticks > 0:
		_on_fuel_tick()
		_fuel_ticks -= 1
	else:
		for fuel_slot in _server_fuel_slots:
			if fuel_slot.is_free():
				continue
			
			var tags: Dictionary = R_Recipe.get_itemstack_tags(fuel_slot.get_item_stack())
			if !tags.has("fuel"):
				continue
			
			var fuel_ticks: int = tags.get("fuel", {}).get("ticks", 50)
			_fuel_ticks = fuel_ticks
			fuel_slot.get_item_stack().quantity -= 1
			return

func try_bake() -> void:
	for recipe in R_Recipe.get_recipe_list():
		for input: CT_InventorySlot in _server_bake_slots:
			var output: CT_InventorySlot = _server_bake_slots[input]
			recipe.try_craft(I_WorldObject.find_in(root).get_object(), input, output)

func _on_fuel_tick() -> void:
	_progress += 1
	if _progress >= _progress_max:
		try_bake()
		_progress = 0
