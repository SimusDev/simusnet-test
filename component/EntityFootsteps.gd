class_name EntityFootsteps extends RayCast3D

@export var entity:Entity 
@export var audio_player:AudioStreamPlayer3D
@export_group("Timer Settings")
@export var walk_time:float = 0.4
@export var sprint_time:float = 0.2

var model:W_AnimatedModel3D
var timer:Timer

var movement:W_FPCSourceLikeMovement

func _ready() -> void:
	set_process( is_multiplayer_authority() )
	set_physics_process( is_multiplayer_authority() )
	set_process_input( is_multiplayer_authority() )
	
	if get_parent() is Entity:
		entity = get_parent()
	
	if is_instance_valid(entity):
		SD_ECS.append_to(entity, EntityFootsteps)
	
	var ecs_model:W_AnimatedModel3D = SD_ECS.find_first_component_by_script(entity, [W_AnimatedModel3D])
	if is_instance_valid(ecs_model):
		model = ecs_model
	
	if not is_instance_valid(audio_player):
		audio_player = AudioStreamPlayer3D.new()
		add_child(audio_player)
	
	if not is_instance_valid(model):
		timer = Timer.new()
		
		timer.wait_time = walk_time
		add_child(timer)
		
		timer.timeout.connect(do_footstep)
	
	if not entity.is_node_ready():
		await entity.ready
		movement = SD_ECS.find_first_component_by_script(entity, [W_FPCSourceLikeMovement])

func do_footstep() -> void:
	if not model:
		if not entity.velocity:
			return
		if movement:
			if timer:
				timer.wait_time = walk_time
				if movement.is_sprinting:
					timer.wait_time = sprint_time
			
			
			if movement.is_crouched:
				return
			
	
	if not is_instance_valid(entity):
		return
	
	if not entity.is_on_floor():
		return
	
	var collider:Node = get_collider()
	if not is_instance_valid(collider):
		return
	
	var metadata:MetadataMaterial = MetadataMaterial.find_in(collider)
	
	if not metadata:
		return
	
	var new_player = audio_player.duplicate()
	add_child(new_player)
	
	new_player.finished.connect(new_player.queue_free)
	
	new_player.stream = metadata.footstep_sounds.pick_random()
	new_player.play()

func _process(_delta: float) -> void:
	if not entity or not timer:
		return
	
	var speed = entity.velocity.length()
	
	if speed > 0.1 and entity.is_on_floor():
		var target_time = sprint_time if (movement and movement.is_sprinting) else walk_time
		
		if timer.wait_time != target_time:
			timer.wait_time = target_time
			if not timer.is_stopped():
				timer.start()
		
		if timer.is_stopped():
			do_footstep()
			timer.start()
	else:
		timer.stop()
