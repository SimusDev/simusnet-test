class_name CT_ActiveLegs extends Node

@export_group("References")
@export var left_leg_ik: TwoBoneIK3D
@export var right_leg_ik: TwoBoneIK3D
@export var target_l: Node3D
@export var target_r: Node3D
@export var left_leg_raycast: RayCast3D
@export var right_leg_raycast: RayCast3D

@export_group("Settings")
@export var foot_offset: float = 0.05
@export var lerp_speed: float = 20.0

func _physics_process(delta: float) -> void:
	# Передаем соответствующий IK узел в функцию
	update_leg(left_leg_raycast, target_l, left_leg_ik, delta)
	update_leg(right_leg_raycast, target_r, right_leg_ik, delta)

# Заменили Marker3D на Node3D и добавили аргумент ik_node
func update_leg(ray: RayCast3D, target: Node3D, ik_node: TwoBoneIK3D, delta: float) -> void:
	if not ray or not target or not ik_node: return

	if ray.is_colliding():
		ik_node.active = true
		var hit_pos = ray.get_collision_point()
		var hit_normal = ray.get_collision_normal()
		
		var goal_pos = hit_pos
		goal_pos.y += foot_offset
		
		# Плавное движение к цели
		target.global_position = target.global_position.lerp(goal_pos, lerp_speed * delta)
		align_foot_to_normal(target, hit_normal, delta)
	else:
		# Плавный возврат к "нулевой" позиции (например, к позиции кости из скелета)
		# Если нет специального узла покоя, можно просто постепенно снижать lerp_speed до выключения
		ik_node.active = false 


func align_foot_to_normal(target: Node3D, normal: Vector3, delta: float) -> void:
	var parent_node = get_parent() as Node3D
	var char_forward = -parent_node.global_transform.basis.z
	
	var foot_up = normal
	var foot_right = foot_up.cross(char_forward).normalized()
	var foot_forward = foot_right.cross(foot_up).normalized()
	
	# Защита от ошибок Cross Product, если нормаль совпадает с форвардом
	if foot_right.length() < 0.001:
		return

	var target_basis = Basis(foot_right, foot_up, foot_forward)
	target.global_transform.basis = target.global_transform.basis.orthonormalized().slerp(target_basis.orthonormalized(), lerp_speed * delta)
