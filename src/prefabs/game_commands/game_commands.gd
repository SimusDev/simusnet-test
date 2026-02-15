extends SD_NodeConsoleCommands

func _ready() -> void:
	super()
	
	SimusNetRPC.register(
		[
			_player_kill
		],
		SimusNetRPCConfig.new()
			.flag_mode_to_server()
	)
	
	on_executed.connect(_on_command_executed)

func _on_command_executed(command:SD_ConsoleCommand) -> void:
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
				command.get_value_as_string()
			)
			
			return
		
		"os.get_unique_id":
			SimusDev.console.write_info("OS Unique id: %s" % OS.get_unique_id())
	
	if command.get_code().begins_with("player.rights."):
			var founded_user: CT_User = _player_find_by_nick(command.get_argument(0))
			if founded_user:
				if command.get_code().ends_with("give"):
					if founded_user.try_give_rights([command.get_argument(1)]):
						pass
					else:
						SD_Console.i().write_warning("can't give rights to %s" % [founded_user.get_nickname()])
				else:
					if founded_user.try_remove_rights([command.get_argument(1)]):
						pass
					else:
						SD_Console.i().write_warning("can't remove rights from %s" % [founded_user.get_nickname()])
		


func _player_find_by_login(login:String) -> CT_User:
	var user: CT_User = CT_User.server_find_by_login(login)
	return user

func _player_find_by_nick(nick: String) -> CT_User:
	var user: CT_User = CT_User.find_by_nickname(nick)
	if !user:
		SD_Console.i().write_warning("can't find user by nick: %s" % nick)
	return user

func _player_kill(nick: String) -> void:
	var sender: CT_User = CT_User.find_by_peer(SimusNetRemote.sender_id)
	if !sender:
		return
	
	var user: CT_User = CT_User.find_by_nickname(nick)
	if !user:
		return
	
	if sender.is_admin():
		var health:CT_Health = SD_ECS.find_first_component_by_script(user.get_player_node(), [CT_Health]) as CT_Health
		if health:
			health.kill()
		else:
			user.get_player_node().queue_free()
	
