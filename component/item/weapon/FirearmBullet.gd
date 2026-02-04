class_name FirearmBullet extends Node3D

var weapon: R_WeaponFirearm
var ammo: R_Ammo

var speed: float = 250.0
var gravity: float = 9.8 
var mass: float = 0.009

var penetration_power: float = 10.0

var exclude_rids:Array[RID]

var velocity: Vector3 = Vector3.ZERO 
var direction: Vector3 = Vector3(0, 0, -1)
var wind_direction: Vector3 = Vector3.ZERO

var life_time:float = 15.0

var last_collider:Node3D = null

const RICOCHET_SOUND = preload("res://src/objects/sound/ricochet_sound.tres")

var bounces_left:int = 1

func _ready() -> void:
	await get_tree().create_timer(life_time).timeout
	queue_free()

func setup_bullet(ammo_res:R_Ammo) -> void:
	ammo = ammo_res
	if not ammo:
		return
	
	direction = -global_transform.basis.z 
	velocity = direction * ammo.muzzle_velocity

func _physics_process(delta: float) -> void:
	if not ammo:
		return
	
	var speed_sq = velocity.length_squared()
	if speed_sq > 0.001:
		var drag_dir = velocity.normalized()
		var drag_accel = (ammo.air_friction * speed_sq / ammo.mass) * drag_dir
		velocity -= drag_accel * delta
	
	velocity.y -= gravity * delta
	velocity += wind_direction * delta
	
	var step = velocity * delta
	
	if not step.is_finite() or step.length_squared() < 0.000001:
		return
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + step)
	query.exclude = exclude_rids
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	
	if result:
		_on_hit(result, step)
	else:
		global_position += step
		if velocity.length() > 0.1:
			var target_pos = global_position + velocity
			if not global_position.is_equal_approx(target_pos):
				var up_dir = Vector3.UP if abs(velocity.normalized().dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
				look_at(target_pos, up_dir)

func _on_hit(result: Dictionary, step: Vector3) -> void:
	var collider = result.get("collider") as Node3D
	if not collider: return
	
	var metadata = MetadataMaterial.safe_find_in(collider)
	var travel_dir = velocity.normalized()
	var normal = result.normal
	
	_spawn_impact_effects(result, metadata)
	
	if collider is RigidBody3D:
		var impulse = velocity * mass 
		collider.apply_impulse(impulse, result.position - collider.global_position)

	
	if collider is RigidBody3D:
		var impulse = velocity.normalized() * mass * velocity.length()
		collider.apply_impulse(impulse, result.position - collider.global_position)
	
	if collider is CT_Hitbox and ammo:
		var _damage = (R_Damage.new()
			.set_value(ammo.base_damage * collider.damage_multiplier)
			.apply(collider.health)
		)
	
	_play_impact_sound(result, metadata)
	
	
	var dot = normal.dot(-travel_dir) 
	if bounces_left > 0:
		if dot < ammo.ricochet_chance:
			velocity = velocity.bounce(normal) * 0.6
			global_position = result.position + normal * 0.01
			bounces_left -= 1
			_play_ricochet_sound(result, metadata)
			return

	var max_depth = ammo.penetration_power * 0.1
	var thickness = _calculate_thickness(result.position, travel_dir, collider, max_depth)
	
	var resistance = metadata.resistance if metadata else 1.0
	var required_power = thickness * resistance

	if ammo.penetration_power > required_power:
		ammo.penetration_power -= required_power
		
		var loss_factor = clamp(required_power / (ammo.penetration_power + required_power + 0.1), 0.1, 0.8)
		velocity *= (1.0 - loss_factor)
		
		var deviation = deg_to_rad(ammo.dispersion_after_penetration)
		velocity = velocity.rotated(Vector3(randf(), randf(), randf()).normalized(), randf_range(-deviation, deviation))
		
		global_position = result.position + travel_dir * (thickness + 0.05)
	else:
		queue_free()
	

func _play_ricochet_sound(result:Dictionary, metadata:MetadataMaterial) -> void:
	s_Sounds.local_play(
		RICOCHET_SOUND,
		self.global_position
	).pitch_scale = randf_range(0.9, 1.2)

#normalno normalno (nadeus memory leak netu))) ) 
func _play_impact_sound(result:Dictionary, metadata:MetadataMaterial) -> void:
	var max_dist:float = 55.0
	var point:Vector3 = result.get("position")
	
	if get_viewport().get_camera_3d().global_position.distance_to(point) > max_dist * 2.0:
		return #nemnozhko optimization )) nation))_)
	if metadata.bullet_impact_sounds.is_empty():
		return # tut 4ut 4ut proverkf na sex
	
	#var collider:Node3D = result.get("collider") as Node3D
	
	var new_audio_player:AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	get_tree().root.add_child(new_audio_player)
	new_audio_player.global_position = point
	new_audio_player.stream = metadata.bullet_impact_sounds.pick_random()
	new_audio_player.unit_size = 3.0
	new_audio_player.max_distance = max_dist
	new_audio_player.pitch_scale = randf_range(0.98, 1.02)
	
	new_audio_player.finished.connect(
		func():
			if is_instance_valid(new_audio_player):
				new_audio_player.queue_free()
	)
	new_audio_player.play()

func _spawn_impact_effects(result: Dictionary, metadata:MetadataMaterial) -> void:
	var collider:Node3D = result.get("collider") as Node3D
	
	var decal = metadata.bullet_impact_decal.instantiate()
	if decal is Node3D:
		collider.add_child(decal)
		decal.global_position = result.position
		if result.normal.is_equal_approx(Vector3.UP):
			decal.look_at(result.position + result.normal, Vector3.LEFT)
		else:
			decal.look_at(result.position + result.normal, Vector3.UP)
		
		decal.rotation.y = randf_range(0, TAU)

func _calculate_thickness(entry_pos: Vector3, direction: Vector3, target: Node3D, max_depth: float) -> float:
	var space_state = get_world_3d().direct_space_state
	var back_point = entry_pos + direction * max_depth
	
	var query = PhysicsRayQueryParameters3D.create(back_point, entry_pos)
	query.collision_mask = target.collision_mask
	
	var exit_result = space_state.intersect_ray(query)
	if exit_result:
		return entry_pos.distance_to(exit_result.position)
	
	return max_depth
