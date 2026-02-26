@tool
class_name AI_Movement extends Node

@export var entity:CharacterBody3D
@export var state_machine:CT_StateMachineSimple

@export_group("State Machine State Names")
@export var state_idle:StringName = "Idle"
@export var state_walk:StringName = "Walk"
@export var state_attack:StringName = "Attack"

var nav_agent: NavigationAgent3D:
	set(val):
		if nav_agent and nav_agent != val:
			nav_agent.queue_free()
		nav_agent = val
		if nav_agent:
			nav_agent.target_reached.connect(_on_target_reached)

var is_rotating:bool = false

static func find_above(node: Node) -> AI_Movement:
	for c in node.get_children():
		if c is AI_Movement:
			return c
	
	for c in node.get_children():
		var found = find_above(c)
		if found:
			return found
	
	return null

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
		entity.call_deferred("add_child", nav_agent)
	

func move_to(pos:Vector3) -> void:
	if not SimusNetConnection.is_server():
		return
	nav_agent.set_target_position(pos)

func move_to_target(target:Node3D) -> void:
	move_to(target.global_position)

func stop() -> void:
	if not SimusNetConnection.is_server():
		return
	move_to(entity.global_position)
	state_machine.try_switch(state_idle)

func _on_target_reached() -> void:
	pass

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if not SimusNetConnection.is_server():
		return
	
	if not nav_agent or not nav_agent.is_inside_tree():
		return

	if nav_agent.is_navigation_finished():
		return

	if nav_agent.target_position:
		var destination: Vector3 = nav_agent.get_next_path_position()
		var local_destination: Vector3 = destination - entity.global_position
		var direction: Vector3 = local_destination.normalized()
		
		var flat_direction = Vector3(direction.x, 0, direction.z).normalized()
		var current_forward = -entity.global_transform.basis.z
		var flat_forward = Vector3(current_forward.x, 0, current_forward.z).normalized()
		
		rotate_towards_direction(flat_direction, delta)
		
		var angle_to_target = flat_forward.angle_to(flat_direction)
		if angle_to_target < 1.5:
			is_rotating = false
		
		if not is_rotating:
			entity.velocity = direction * 2.0 # movespeed
			entity.move_and_slide()
	
	if state_machine.get_current_state() == state_attack:
		return
	
	if entity.velocity:
		state_machine.try_switch(state_walk)
	else:
		state_machine.try_switch(state_idle)


func rotate_towards_direction(target_direction: Vector3, delta: float) -> void:
	is_rotating = true
	var current_transform = entity.global_transform
	var current_forward = -current_transform.basis.z
	
	var flat_current = Vector3(current_forward.x, 0, current_forward.z).normalized()
	var flat_target = Vector3(target_direction.x, 0, target_direction.z).normalized()
	
	var rotation_amount = 1.0 * delta 
	var new_direction = flat_current.slerp(flat_target, rotation_amount).normalized()
	
	if new_direction.length() > 0.001:
		var look_at_point = entity.global_position + new_direction
		entity.look_at(look_at_point, Vector3.UP)
