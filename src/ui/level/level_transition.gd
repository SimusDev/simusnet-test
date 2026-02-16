extends ColorRect
class_name UI_LevelTransition

static var _instance: UI_LevelTransition

@onready var _icon: TextureRect = $Panel/_Icon

@onready var _logger: SD_Logger = SD_Logger.new(self)

func _ready() -> void:
	_instance = self

func ___set_level(level: R_Level) -> void:
	if !level:
		_logger.debug("set_level(): level is null!", SD_ConsoleCategories.ERROR)
		return
	
	

static func set_level(level: R_Level) -> UI_LevelTransition:
	_instance.___set_level(level)
	return _instance

func _on_yes_pressed() -> void:
	pass # Replace with function body.

func _on_no_pressed() -> void:
	hide()
