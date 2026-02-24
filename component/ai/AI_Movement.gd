@tool
class_name AI_Movement extends Node

@export var entity_ai:EntityAI

var nav_agent:NavigationAgent3D :
	set(val):
		if nav_agent:
			nav_agent.queue_free()
		
		nav_agent = val
		nav_agent.target_reached.connect(_on_target_reached)

var is_rotating:bool = false

func _ready() -> void:
	var is_server:bool = SimusNetConnection.is_server()
	set_process(is_server)
	set_physics_process(is_server)
	
	if not is_server:
		return
	
	_auto_update()

func _auto_update() -> void:
	if not nav_agent:
		nav_agent = NavigationAgent3D.new()
		add_child(nav_agent)
	
	if not entity_ai:
		var parent = get_parent()
		if parent is EntityAI:
			entity_ai = parent

func move_to(pos:Vector3) -> void:
	if not SimusNetConnection.is_server():
		return
	nav_agent.set_target_position(pos)

func move_to_target(target:Node3D) -> void:
	move_to(target.global_position)

func stop() -> void:
	if not SimusNetConnection.is_server():
		return
	move_to(entity_ai.root.global_position)

func _on_target_reached() -> void:
	pass

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if not SimusNetConnection.is_server():
		return
	
	if nav_agent.target_position:
		var destination: Vector3 = nav_agent.get_next_path_position()
		var local_destination: Vector3 = destination - entity_ai.root.global_position
		var direction: Vector3 = local_destination.normalized()
		
		var flat_direction = Vector3(direction.x, 0, direction.z).normalized()
		var current_forward = -entity_ai.root.global_transform.basis.z
		var flat_forward = Vector3(current_forward.x, 0, current_forward.z).normalized()
		
		rotate_towards_direction(flat_direction, delta)
		
		var angle_to_target = flat_forward.angle_to(flat_direction)
		if angle_to_target < 1.5:
			is_rotating = false
		
		if not is_rotating:
			entity_ai.root.velocity = direction * 10.0 # movespeed
			entity_ai.root.move_and_slide()


func rotate_towards_direction(target_direction: Vector3, delta: float) -> void:
	is_rotating = true
	var current_transform = entity_ai.root.global_transform
	var current_forward = -current_transform.basis.z
	
	var flat_current = Vector3(current_forward.x, 0, current_forward.z).normalized()
	var flat_target = Vector3(target_direction.x, 0, target_direction.z).normalized()
	
	var rotation_amount = 10.0 * delta 
	var new_direction = flat_current.slerp(flat_target, rotation_amount).normalized()
	
	if new_direction.length() > 0.001:
		var look_at_point = entity_ai.root.global_position + new_direction
		entity_ai.root.look_at(look_at_point, Vector3.UP)
