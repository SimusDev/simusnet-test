class_name W_WeaponFirearm extends W_Item

signal event_reload
signal event_fire
signal event_fire_empty

signal event_aim_enter
signal event_aim_exit

@export var muzzle_flash:GPUParticles3D

@export var shell_point:Node3D
@export var muzzle_point:Node3D

var firearm_object: R_WeaponFirearm

var alt_state_machine: CT_StateMachineSimple
var exclude_rids:Array[RID]

static func find_above(node:Node) -> W_WeaponFirearm:
	return super(node) as W_WeaponFirearm

func _get_stack() -> CT_ItemStackFireArmWeapon:
	return super() as CT_ItemStackFireArmWeapon

func _ready() -> void:
	super()
	firearm_object = object as R_WeaponFirearm
	randomize()
	
	var rpc_config = SimusNetRPCConfig.new()
	
	SimusNetRPC.register(
		[
			_request_reload_server,
		],
		rpc_config
	)
	
	SimusNetRPC.register(
		[
			_request_reload_receive,
		],
		SimusNetRPCConfig.new().flag_set_channel("item").flag_serialization().flag_mode_server_only()
	)
	
	var entity = entity_head.get_entity()
	if entity is Entity:
		exclude_rids = entity.find_collisions_rids_above()

func _state_machine_init() -> void:
	#state_machine.debug = true
	state_machine.add_state("idle").add_state("fire")
	state_machine.add_state("reload")

func _state_machine_transitioned(from: String, to: String) -> void:
	pass

func _local_input(event: InputEvent) -> void:
	super(event)
	
	if Input.is_action_just_pressed("weapon.reload"):
		request_reload()

func request_reload() -> void:
	if state_machine.get_current_state() == "idle":
		if is_local() and _get_stack().can_reload():
			SimusNetRPC.invoke_on_server(_request_reload_server)

func _request_reload_server() -> void:
	if !_get_stack().can_reload():
		return
	
	if _get_stack().try_reload():
		SimusNetRPC.invoke_on_sender(_request_reload_receive)

func _request_reload_receive() -> void:
	event_reload.emit()
	state_machine.try_switch("reload").make_cooldown_and_switch_to(firearm_object.reload_time, "idle")

func __pressed_alt_net() -> void:
	event_aim_enter.emit()

func __released_alt_net() -> void:
	event_aim_exit.emit()

func request_press() -> void:
	super()
	if state_machine.get_current_state() == "idle" and _get_stack().bullets > 0:
		state_machine.try_switch("fire")

func request_release() -> void:
	super()
	if state_machine.get_current_state() == "fire":
		state_machine.try_switch("idle")

func _process(_delta: float) -> void:
	if state_machine.get_current_state() == "fire":
		fire()

func fire() -> void:
	if _get_stack().bullets <= 0 or !can_use():
		return
	
	cooldown_timer.start()
	if muzzle_flash:
		muzzle_flash.emitting = true
	if SimusNetConnection.is_server():
		_get_stack().bullets -= 1
	
	_spawn_bullet()
	_muzzle_fire()
	_spawn_fake_bullet()
	
	play_fire_sound()
	event_fire.emit()

func _muzzle_fire() -> void:
	pass

func _spawn_bullet() -> void:
	var bullet = load("res://scenes/prefabs/firearm_bullet.tscn").instantiate()
	bullet.set("weapon", object)
	bullet.set("exclude_rids", exclude_rids)
	
	get_tree().root.add_child(bullet)
	
	bullet.global_transform = entity_head.get_eyes().global_transform
	
	if bullet.has_method("setup_bullet"):
		bullet.setup_bullet()

func _spawn_fake_bullet() -> void:
	pass

func play_fire_sound():
	var rand_pitch:float = randf_range(.95, 1.05)
	object = object as R_WeaponFirearm 
	if object.shot_sound:
		object.shot_sound.play(
			entity_head.get_eyes(),
			entity_head.get_eyes().global_position,
			rand_pitch
			)
