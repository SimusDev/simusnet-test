extends SD_NodeConsoleCommands

func _ready() -> void:
	super()
	on_executed.connect(_on_command_executed)

func _on_command_executed(command:SD_ConsoleCommand) -> void:
	match command.get_code():
		"player.kill":
			SimusNetRPC.invoke_on_server(
				_player_kill,
				command.get_value_as_string()
			)
			
			return

func _player_kill(login:String) -> void:
	var user = CT_User.server_find_by_login(login)
	if not user:
		return
	
	var health:CT_Health = SD_ECS.find_first_component_by_script(user.get_player_node(), [CT_Health]) as CT_Health
	if health:
		health.kill()
	else:
		user.get_player_node().queue_free()
	pass
