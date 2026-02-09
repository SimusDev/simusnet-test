class_name W_WeaponMelee extends W_Item

signal event_fire

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
	
	s_Sounds.local_play(object.swing_sound, self.global_position)
	
	if _character_animations:
		_character_animations.get_or_create("weapon_melee_swing").publish(self)
	
	event_fire.emit()

func impact() -> void:
	SimusNetRPC.invoke_on_server(local_impact)

func local_impact() -> void:
	var space_state = get_world_3d().direct_space_state
	var origin = entity_head.get_eyes().global_position
	var target = origin - entity_head.get_eyes().global_transform.basis.z * object.attack_range
	
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	
	query.exclude = [entity_head.get_entity().get_rid()] 
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		s_Sounds.local_play(object.impact_sound, result.position)
		if collider is CT_Hitbox:
			var dmg:R_Damage = R_Damage.new()
			dmg.set_value(object.damage)
			dmg.apply(collider.health)
