class_name W_WeaponFirearm extends W_Item

signal event_reload
signal event_fire
signal event_fire_empty

@export var muzzle_flash:GPUParticles3D

@export var shell_point:Node3D
@export var muzzle_point:Node3D

var firearm_object: R_WeaponFirearm

var alt_state_machine: CT_StateMachineSimple
var exclude_rids:Array[RID]

const BULLET_SCENE = preload("res://scenes/prefabs/firearm_bullet.tscn")

var _ammo_packs_ui: R_UI

static func find_above(node:Node) -> W_WeaponFirearm:
	return super(node) as W_WeaponFirearm

func _get_stack() -> CT_ItemStackFireArmWeapon:
	return super() as CT_ItemStackFireArmWeapon

func _ready() -> void:
	super()
	_ammo_packs_ui = R_UI.find_by_id("ui:ammo_packs")
	
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
	
	if entity:
		exclude_rids = entity.find_collisions_rids_above()
	
	_get_or_create_sound("reload").max_distance = 15

func _state_machine_init() -> void:
	#state_machine.debug = true
	state_machine.add_state("idle").add_state("fire")
	state_machine.add_state("reload")

func _state_machine_transitioned(from: String, to: String) -> void:
	match to:
		"reload":
			_get_or_create_sound("reload").stream = firearm_object.reload_sound
			_get_or_create_sound("reload").play()
			event_reload.emit()
			if _character_animations:
				_character_animations.get_or_create("firearm_reload").publish(self)

func _local_input(event: InputEvent) -> void:
	super(event)
	
	if Input.is_action_just_pressed("weapon.reload"):
		request_reload()
	

func _local_input_no_interface_check(event: InputEvent) -> void:
	if Input.is_action_just_pressed("change_ammo_type"):
		var ui: Control = await _ammo_packs_ui.async_get_instance()
		ui.set_item(self)
		ui.set_pack(_get_stack()._firearm.ammo_pack)
		ui.visible = !ui.visible

func _exit_tree() -> void:
	if is_local():
		var ui: Control = await _ammo_packs_ui.async_get_instance()
		ui.hide()

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
	state_machine.try_switch("reload").make_cooldown_and_switch_to(firearm_object.reload_time, "idle")

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
		if can_use():
			fire()

func fire() -> void:
	if _get_stack().bullets <= 0:
		return
	
	if SimusNetConnection.is_server():
		_get_stack().bullets -= 1
	
	cooldown_timer.start()
	if muzzle_flash:
		muzzle_flash.emitting = true
	
	
	_spawn_bullet()
	_spawn_fake_bullet()
	
	event_fire.emit()
	
	if firearm_object.shot_sound:
		s_Sounds.local_play(firearm_object.shot_sound, self.global_position)
	
	if _character_animations:
		_character_animations.get_or_create("firearm_shoot").publish(self)
	


func _spawn_bullet() -> void:
	var bullet: Node = _get_stack().ammo.get_prefab().instantiate()
	
	if bullet is FirearmBullet:
		bullet.weapon = firearm_object 
		
		bullet.exclude_rids = exclude_rids
		
		level.add_child(bullet)
		
		var base_direction = -entity_eyes.global_transform.basis.z
		var dispersion_radians = deg_to_rad(firearm_object.base_dispersion)
	
		var spread_rotation = Basis().rotated(Vector3.UP, randf_range(-dispersion_radians, dispersion_radians))
		spread_rotation *= Basis().rotated(Vector3.RIGHT, randf_range(-dispersion_radians, dispersion_radians))
		
		var final_direction = (spread_rotation * base_direction).normalized()
	
		if muzzle_point:
			bullet.global_position = muzzle_point.global_position
		elif entity_eyes:
			bullet.global_transform = entity_eyes.global_transform
		
		if final_direction.length() > 0.001:
			bullet.look_at(bullet.global_position + final_direction)
		
		bullet.setup_bullet(_get_stack().ammo)

func _spawn_fake_bullet() -> void:
	pass
