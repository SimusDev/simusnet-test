extends ColorRect
class_name UI_LevelTransition

static var _instance: UI_LevelTransition

@onready var _icon: TextureRect = $Panel/_Icon

@onready var _logger: SD_Logger = SD_Logger.new(self)
@onready var _cooldown: Timer = $cooldown

var _level: R_Level

func _ready() -> void:
	_instance = self

func ___set_level(level: R_Level) -> void:
	_level = level
	if !level:
		_logger.debug("set_level(): level is null!", SD_ConsoleCategories.ERROR)
		return
	

static func try_show_with_cooldown() -> void:
	if _instance._cooldown.is_stopped():
		_instance.show()
		_instance._cooldown.start()
	

static func set_level(level: R_Level) -> UI_LevelTransition:
	_instance.___set_level(level)
	return _instance

func _on_yes_pressed() -> void:
	hide()
	
	var player: CT_Playable = CT_Playable.get_local()
	if player:
		player.get_level().get_handler().request_transition_to_level()
	

func _on_no_pressed() -> void:
	hide()
