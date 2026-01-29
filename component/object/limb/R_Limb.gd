class_name R_Limb extends R_WorldObject

enum LimbType {
	ARM,
	LEG
}

enum LimbSide {
	LEFT,
	RIGHT
}

@export var type:LimbType = LimbType.ARM
@export var side:LimbSide = LimbSide.LEFT

@export var settings:R_LimbSettings

func _init() -> void:
	if not settings:
		var new_settings = R_LimbSettings.new()
		settings = new_settings
