extends SD_NodeConsoleCommands

func _ready() -> void:
	super()
	on_executed.connect(_on_command_executed)

func _on_command_executed(command:SD_ConsoleCommand) -> void:
	match command.get_code():
		"player.kill":
			if command.get_arguments().size() < 1:
				return
			var user = CT_User.server_find_by_login(command.get_value_as_string())
			var health:CT_Health = SD_ECS.find_first_component_by_script(user.get_player_node(), [CT_Health]) as CT_Health
			if health:
				health.kill()
			return
