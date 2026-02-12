extends Node3D

func _ready() -> void:
	if is_multiplayer_authority():
		$AnimationPlayer.play("idle")
