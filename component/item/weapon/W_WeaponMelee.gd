class_name W_WeaponMelee extends W_Item

signal event_fire
signal event_enter_idle

var player_camera:W_FPCSourceLikeCamera

func _ready() -> void:
	super()
	SimusNetRPC.register(
		[
			local_impact
		],
		net_config
	)

func _process(_delta: float) -> void:
	if is_using:
		fire()

func fire() -> void:
	if not can_use():
		return
		
	cooldown_timer.start()
	#
	if object is R_WeaponMelee:
		object.swing_sound.play(player, player.global_position)
	#
	event_fire.emit()

func impact() -> void:
	SimusNetRPC.invoke_on_server(local_impact)

func local_impact() -> void:
	if not player_camera:
		player_camera = SD_Components.find_first(player, W_FPCSourceLikeCamera)
	
	if not player_camera:
		return
	
	var space_state = get_world_3d().direct_space_state
	var origin = player_camera.global_position
	var target = origin - player_camera.global_transform.basis.z * object.attack_range
	
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	
	query.exclude = [player.get_rid()] 
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		object.impact_sound.play(collider, result.position)
		if collider is CT_Hitbox:
			var dmg:R_Damage = R_Damage.new()
			dmg.set_value(object.damage)
			dmg.apply(collider.health)
