class_name W_WeaponFirearm extends W_Item

signal event_reload
signal event_fire

signal event_aim_enter
signal event_aim_exit

@export var shell_point:Node3D
@export var muzzle_point:Node3D

var firearm_object: R_WeaponFirearm

var alt_state_machine: CT_StateMachineSimple
var exclude_rids:Array[RID]

func _ready() -> void:
	super()
	firearm_object = object as R_WeaponFirearm
	randomize()
	
	var rpc_config = SimusNetRPCConfig.new()
	
	SimusNetRPC.register(
		[
			
		],
		rpc_config
	)
	
	if SimusNetConnection.is_server():
		stack.metadata_put_or_get("bullets", 0)
	var entity = entity_head.get_entity()
	if entity is Entity:
		exclude_rids = entity.find_collisions_rids_above()

func _state_machine_init() -> void:
	state_machine.debug = true
	state_machine.add_state("idle").add_state("fire")
	state_machine.add_state("reload")

func _state_machine_transitioned(from: String, to: String) -> void:
	pass

func _local_input(event: InputEvent) -> void:
	super(event)
	if Input.is_action_just_pressed("weapon.reload"):
		event_reload.emit()

func __pressed_alt_net() -> void:
	event_aim_enter.emit()
	
	if !is_local():
		return
	

func __released_alt_net() -> void:
	event_aim_exit.emit()
	

func _process(_delta: float) -> void:
	if is_using:
		fire()

func fire() -> void:
	if not can_use():
		return
	
	cooldown_timer.start()
	
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
