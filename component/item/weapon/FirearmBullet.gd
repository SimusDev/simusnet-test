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
		_on_hit(result, step)
	else:
		global_position += step
		if velocity.length() > 1.0:
			look_at(global_position + velocity)

func _on_hit(result: Dictionary, step: Vector3) -> void:
	_spawn_impact_effects(result)
	var collider = result.get("collider") as Node3D
	
	#if SimusNetConnection.is_server():
	
	
	if collider is CT_Hitbox:
		var damage = (R_Damage.new()
			.set_value( 25.0 * collider.damage_multiplier)
			.apply(collider.health)
		)
	
	var resistance = 1.0 ## 1.0 эта типа бетон
	if MetadataMaterial.find_in(collider):
		var metadata:MetadataMaterial = MetadataMaterial.find_in(collider)
		resistance = metadata.resistance
	
	var speed_loss = resistance * 150.0 
	var new_speed = velocity.length() - speed_loss
	
	if new_speed > 50.0:
		velocity = velocity.normalized() * new_speed
		global_position = result.position + velocity.normalized() * 0.1 #типа хрень какая то хз
	else:
		queue_free()

func _spawn_impact_effects(result: Dictionary) -> void:
	pass
