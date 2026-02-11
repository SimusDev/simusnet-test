extends Node3D

var explosion: Node3D

var _state: int = 0

func _ready() -> void:
	scale = Vector3(explosion._scale, explosion._scale, explosion._scale)
	$AnimationPlayer.speed_scale = 1.0 / explosion._scale
	$SD_SoundInstance3D.instance_play()

func _check_deletion() -> void:
	if _state >= 2:
		queue_free()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	_state += 1
	_check_deletion()

func _on_sd_sound_instance_3d_on_play_finish() -> void:
	_state += 1
	_check_deletion()
