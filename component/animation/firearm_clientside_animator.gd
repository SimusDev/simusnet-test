@tool
extends Node
class_name FirearmClientSideAnimator

@export var animation_player: AnimationPlayer

@export_group("Animations")
@export var anim_pickup: Array[StringName]
@export var anim_idle: Array[StringName]
@export var anim_shoot: Array[StringName]
@export var anim_reload: Array[StringName]

@export var muzzleflash_particles: Array[GPUParticles3D]

@export_group("Positioning")
@export var editor_process: bool = false
@export var is_aiming: bool = false
@export var root: Node3D
@export var default_position: Vector3
@export var default_rotation: Vector3
@export var aim_position: Vector3
@export var aim_rotation: Vector3
@export var interp_speed: float = 10.0


var _item: W_WeaponFirearm

var _logger: SD_Logger = SD_Logger.new(self)

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	else:
		is_aiming = false
	
	_item = W_WeaponFirearm.find_above(self)
	
	if !_item:
		_logger.debug("cant find item above", SD_ConsoleCategories.ERROR)
		return
	
	_item.event_aim_enter.connect(_set_aim.bind(true))
	_item.event_aim_exit.connect(_set_aim.bind(false))
	_item.event_fire.connect(_play_animation.bind(anim_shoot))
	_item.event_fire.connect(_play_particles.bind(muzzleflash_particles))
	_item.event_reload.connect(_play_animation.bind(anim_reload))
	_item.event_pick.connect(_play_animation.bind(anim_pickup))

func _play_particles(particles: Array[GPUParticles3D]) -> void:
	for i in particles:
		i.emitting = true

func _play_animation(anims: Array[StringName]) -> void:
	if anims.is_empty():
		_logger.debug("animations is empty!, failed play animations %s" % str(anims))
		return
	if !animation_player:
		_logger.debug("animation player is null!, failed play animations %s" % str(anims))
		return
	
	animation_player.stop()
	animation_player.play(anims.pick_random())

func _set_aim(value: bool) -> void:
	is_aiming = value

func _process(delta: float) -> void:
	if !is_instance_valid(root) or (Engine.is_editor_hint() and !editor_process):
		return
	
	var target_position: Vector3 = default_position
	var target_rotation: Vector3 = default_rotation
	
	if is_aiming:
		target_position = aim_position
		target_rotation = aim_rotation
	
	
	root.position = lerp(root.position, target_position, delta * interp_speed)
	
	root.rotation.x = lerp_angle(root.rotation.x, target_rotation.x, delta * interp_speed)
	root.rotation.y = lerp_angle(root.rotation.y, target_rotation.y, delta * interp_speed)
	root.rotation.z = lerp_angle(root.rotation.z, target_rotation.z, delta * interp_speed)
