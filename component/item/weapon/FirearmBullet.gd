class_name FirearmBullet extends Node3D

var weapon: R_WeaponFirearm

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

func _ready() -> void:
	direction = -global_transform.basis.z 
	velocity = direction * speed
	
	await get_tree().create_timer(life_time).timeout
	queue_free()

func setup_bullet() -> void:
	direction = -global_transform.basis.z 
	velocity = direction * speed

func _physics_process(delta: float) -> void:
	velocity.y -= gravity * delta
	var step = velocity * delta
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + step)
	query.exclude = exclude_rids
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	
	if result:
		if result.collider != last_collider:
			_on_hit(result, step)
			last_collider = result.collider
	else:
		global_position += step
		if velocity.length() > 1.0:
			look_at(global_position + velocity)

func _on_hit(result: Dictionary, step: Vector3) -> void:
	var collider = result.get("collider") as Node3D
	var metadata = MetadataMaterial.safe_find_in(collider)
	_spawn_impact_effects(result, metadata)
	
	
	if collider is CT_Hitbox:
		var _damage = (R_Damage.new()
			.set_value( 25.0 * collider.damage_multiplier)
			.apply(collider.health)
		)
	
	_play_impact_sound(result, metadata)
	
	var speed_loss = metadata.resistance * 150.0 
	var new_speed = velocity.length() - speed_loss
	
	if new_speed > 50.0:
		velocity = velocity.normalized() * new_speed
		global_position = result.position + velocity.normalized() * 0.1 #типа хрень какая то хз
	else:
		queue_free()

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
	
	#var particles = metadata.bullet_impact_particles.instantiate()
	#if particles is GPUParticles3D:
		#collider.add_child(particles)
		#particles.global_position = result.position
		#particles.emitting = true
