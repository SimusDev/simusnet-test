extends SD_NodeConsoleCommands

func _ready() -> void:
	super()
	
	SimusNetRPC.register(
		[
			_player_kill
		],
		SimusNetRPCConfig.new()
			.flag_mode_any_peer()
	)
	
	on_executed.connect(_on_command_executed)

func _on_command_executed(command:SD_ConsoleCommand) -> void:
	print(OS.get_unique_id())
	match command.get_code():
		"suicide":
			if command.get_arguments().size() > 0:
				return
			var user = CT_User.get_local()
			if not user:
				return
			SimusNetRPC.invoke_on_server(
				_player_kill,
				user
			)
			return
		
		"player.kill":
			if !(command.get_arguments().size() == 1):
				return
			SimusNetRPC.invoke_on_server(
				_player_kill,
				_player_find_by_login(command.get_value_as_string())
			)
			
			return
		
		"os.get_unique_id":
			SimusDev.console.write_info("OS Unique id: %s" % OS.get_unique_id())

func _player_find_by_login(login:String) -> CT_User:
	return CT_User.server_find_by_login(login)

func _player_kill(user:CT_User) -> void:
	if not user:
		return
	
	var health:CT_Health = SD_ECS.find_first_component_by_script(user.get_player_node(), [CT_Health]) as CT_Health
	if health:
		health.kill()
	else:
		user.get_player_node().queue_free()
	pass
