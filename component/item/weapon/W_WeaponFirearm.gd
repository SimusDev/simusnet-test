class_name W_WeaponFirearm extends W_Item

signal event_reload
signal event_fire

@export var shell_point:Node3D
@export var bullet_point:Node3D

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
	
	play_fire_sound()
	
	event_fire.emit()

func play_fire_sound():
	var rand_pitch:float = randf_range(.95, 1.05)
	object = object as R_WeaponFirearm 
	if object.sound:
		object.shot_sound.play()
