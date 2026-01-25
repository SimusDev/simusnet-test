class_name W_WeaponFirearm extends W_Item

signal event_reload
signal event_fire

@export var shell_point:Node3D
@export var muzzle_point:Node3D

func _ready() -> void:
	super()
	randomize()
	
	var rpc_config = SimusNetRPCConfig.new()
	
	SimusNetRPC.register(
		[
			
		],
		rpc_config
	)


func _input(event: InputEvent) -> void:
	super(event)
	if Input.is_action_just_pressed("weapon.reload"):
		event_reload.emit()

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
	if not is_multiplayer_authority():
		return
	
	var bullet = load("res://scenes/prefabs/firearm_bullet.tscn").instantiate()
	bullet.set("weapon", object)
	get_tree().root.add_child(bullet)

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
