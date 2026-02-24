class_name AI_EyeRay extends RayCast3D

var target_peer:int = -1 :
	set(val):
		target_peer = val
		_update_target()

var target:Node3D


func _update_target() -> void:
	if target_peer < 0:
		return
	
	var user = CT_User.find_by_peer(target_peer)
	if not user:
		return
	
	var player = user.get_player_node()
	
	if not is_instance_valid(player):
		return
	
	if not player is Node3D:
		return
	
	target = player

func update() -> void:
	if not target:
		_update_target()
	
	look_at(target.global_position)
