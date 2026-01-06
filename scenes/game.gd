extends Node3D

func _ready() -> void:
	SimusNetRPC.register([
		_test
	],
	SimusNetRPCConfig.new().flag_mode_server_only()
	)
	

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://scenes/test.tscn")

func _on_timer_timeout() -> void:
	if SimusNetConnection.is_server():
		var data: Dictionary = {
		}
		return
		SimusNetRPC.invoke(_test, SD_Variables.compress(data))
		

func _test(v1: Variant = null, v2: Variant = null, v3: Variant = null) -> void:
	print("%s hello from: %s" % [v1, SimusNetRemote.sender_id])
