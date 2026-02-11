class_name FirearmBullet extends Node3D

signal setup

var weapon: R_WeaponFirearm
var ammo: R_Ammo

var gravity: float = 9.8 
var penetration_power: float = 10.0
var current_pen_power: float = 0.0 
var exclude_rids: Array[RID]

var velocity: Vector3 = Vector3.ZERO 
var wind_direction: Vector3 = Vector3.ZERO
var life_time: float = 15.0

const RICOCHET_SOUND = preload("res://src/objects/sound/ricochet_sound.tres")
var bounces_left: int = 78

var _initial_speed: float = 0.0

var is_setup:bool = false

func _ready() -> void:
	if not is_setup:
		await setup
	get_tree().create_timer(life_time).timeout.connect(queue_free)

func setup_bullet(ammo_res: R_Ammo) -> void:
	ammo = ammo_res
	if not ammo:
		return
	
	penetration_power = ammo.penetration_power
	var direction = -global_transform.basis.z 
	velocity = direction * ammo.muzzle_velocity
	_initial_speed = ammo.muzzle_velocity
	
	is_setup = true
	setup.emit()

func _physics_process(delta: float) -> void:
	if not is_setup:
		await setup
	if not ammo or ammo.mass < 0.0001: return
	
	var speed = velocity.length()
	if speed > 1.0:
		var drag_force = ammo.air_friction * speed * speed
		var drag_accel = drag_force / ammo.mass
		
		var max_deceleration = (speed * 0.9) / delta
		drag_accel = min(drag_accel, max_deceleration)
		
		velocity -= velocity.normalized() * drag_accel * delta
	
	velocity.y -= gravity * delta
	velocity += wind_direction * delta
	
	var step = velocity * delta
	if step.length_squared() < 0.000001:
		queue_free()
		return
	
	if velocity.length_squared() > 0.1:
		var target_pos = global_position + velocity
		var up_vec = Vector3.UP if abs(velocity.normalized().dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
		look_at(target_pos, up_vec)
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + step)
	query.exclude = exclude_rids
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	if result:
		_on_hit(result)
	else:
		global_position += step

func _on_hit(result: Dictionary) -> void:
	var collider = result.get("collider") as Node3D
	if not is_instance_valid(collider): return
	
	var metadata = MetadataMaterial.safe_find_in(collider)
	var travel_dir = velocity.normalized()
	var velocity_before = velocity
	var normal = result.normal
	
	_spawn_impact_effects(result, metadata)
	_play_impact_sound(result, metadata)

	var speed_mult = velocity.length() / _initial_speed
	var effective_pen = current_pen_power * speed_mult

	var dot_product = normal.dot(-travel_dir) 
	if bounces_left > 0 and dot_product < ammo.ricochet_chance:
		var rndf = randf_range(0.0, .6)
		if rndf < ammo.ricochet_chance:
			velocity = velocity.bounce(normal) * 0.5
			global_position = result.position + normal * 0.02
			bounces_left -= 1
			_play_ricochet_sound(result, metadata)
			_apply_physics_impulse(collider, velocity_before, velocity, result.position)
			return

	var resistance = metadata.resistance if metadata else 1.0
	var required_energy_per_cm = resistance 
	
	var max_possible_depth = effective_pen / (required_energy_per_cm + 0.001)
	var thickness = _calculate_thickness(result.position, travel_dir, collider, max_possible_depth)
	var energy_cost = thickness * required_energy_per_cm

	if effective_pen > energy_cost:
		current_pen_power -= energy_cost
		
		var speed_loss_factor = clamp(energy_cost / (effective_pen + 0.1), 0.15, 0.9)
		velocity *= (1.0 - speed_loss_factor)
		
		var spread = deg_to_rad(ammo.dispersion_after_penetration)
		var random_dir = (Vector3(randf(), randf(), randf()) - Vector3(0.5, 0.5, 0.5)).normalized()
		velocity = velocity.rotated(random_dir, randf_range(-spread, spread))
		
		_apply_physics_impulse(collider, velocity_before, velocity, result.position)
		_apply_damage(collider, velocity_before.length())
		
		global_position = result.position + travel_dir * (thickness + 0.05)
	else:
		_apply_physics_impulse(collider, velocity_before, Vector3.ZERO, result.position)
		_apply_damage(collider, velocity_before.length())
		queue_free()

func _apply_physics_impulse(collider: Node, v_before: Vector3, v_after: Vector3, hit_pos: Vector3) -> void:
	if not SimusNetConnection.is_server(): return
	if collider is RigidBody3D:
		var impulse = (v_before - v_after) * ammo.mass
		collider.apply_impulse(impulse, hit_pos - collider.global_position)

func _apply_damage(collider: Node, speed_at_impact: float) -> void:
	if not SimusNetConnection.is_server(): return
	if collider is CT_Hitbox:
		var speed_ratio = speed_at_impact / _initial_speed
		var final_damage = ammo.base_damage * collider.damage_multiplier * speed_ratio
		
		var dmg = R_Damage.new()
		dmg.set_value(final_damage).apply(collider.health)

func _calculate_thickness(entry_pos: Vector3, travel_dir: Vector3, _target: Node, max_p_depth: float) -> float:
	var space_state = get_world_3d().direct_space_state
	var test_depth = max(max_p_depth, 0.01)
	var back_point = entry_pos + travel_dir * (test_depth + 0.01)
	
	var query = PhysicsRayQueryParameters3D.create(back_point, entry_pos)
	query.hit_back_faces = true
	
	var exit_result = space_state.intersect_ray(query)
	if exit_result:
		return entry_pos.distance_to(exit_result.position)
	return test_depth

func _play_ricochet_sound(result: Dictionary, _metadata: MetadataMaterial) -> void:
	s_Sounds.local_play(RICOCHET_SOUND, result.position).pitch_scale = randf_range(0.9, 1.2)

func _play_impact_sound(result: Dictionary, metadata: MetadataMaterial) -> void:
	if not metadata or metadata.bullet_impact_sounds.is_empty(): return
	
	var cam = get_viewport().get_camera_3d()
	var distance = cam.global_position.distance_to(result.position)
	
	if distance > 60.0:
		return 
	
	
	var audio = AudioStreamPlayer3D.new()
	get_tree().root.add_child(audio)
	audio.global_position = result.position
	audio.stream = metadata.bullet_impact_sounds.pick_random()
	audio.unit_size = 3.0
	audio.max_distance = 60.0
	audio.bus = &"SFX"
	audio.finished.connect(audio.queue_free)
	audio.play()

func _spawn_impact_effects(result: Dictionary, metadata: MetadataMaterial) -> void:
	if not metadata or not metadata.bullet_impact_decal: return
	var collider = result.collider
	if not is_instance_valid(collider): return

	var decal = metadata.bullet_impact_decal.instantiate()
	collider.add_child(decal)
	var pos = result.position
	var normal = result.normal

	var y_axis = normal
	var x_axis = Vector3.UP.cross(y_axis).normalized()
	
	if x_axis.length_squared() < 0.001:
		x_axis = Vector3.RIGHT.cross(y_axis).normalized()
	
	var z_axis = x_axis.cross(y_axis).normalized()
	
	decal.global_transform.basis = Basis(x_axis, y_axis, z_axis)
	decal.global_position = pos
	
	decal.rotate_object_local(Vector3.UP, randf() * TAU)
