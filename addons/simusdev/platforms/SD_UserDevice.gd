@static_unload
@tool
extends RefCounted
class_name SD_UserDevice

enum TYPE {
	DESKTOP,
	MOBILE,
	TABLET,
	TV,
}

static var TYPE_STRING: Dictionary[TYPE, String] = {
	TYPE.DESKTOP: "desktop",
	TYPE.MOBILE: "mobile",
	TYPE.TABLET: "tablet",
	TYPE.TV: "tv",
}

static func set_type(type: TYPE) -> SD_UserDevice:
	_type = type
	update_type(true)
	return _instance

static func type_to_string(type: TYPE) -> String:
	return TYPE_STRING.get(type)

signal on_type_changed()

static var _instance: SD_UserDevice

static var _type: int = TYPE.DESKTOP

func _ready() -> void:
	if SD_Platforms.is_mobile():
		_type = TYPE.MOBILE
	
	update_type(true)

static func update_type(write_message: bool = false) -> SD_UserDevice:
	if write_message:
		SD_Console.i().write_info("User Device: %s" % type_to_string(_type))
	_instance.on_type_changed.emit()
	return _instance

static func connect_type_changed_signal(callable: Callable) -> SD_UserDevice:
	_instance.on_type_changed.connect(callable)
	return _instance

static func get_type() -> TYPE:
	return _type

static func is_desktop() -> bool:
	return _type == TYPE.DESKTOP

static func is_mobile() -> bool:
	return _type == TYPE.MOBILE

static func is_tablet() -> bool:
	return _type == TYPE.TABLET

static func is_tv() -> bool:
	return _type == TYPE.TV

static func is_mobile_or_tablet() -> bool:
	return is_mobile() or is_tablet()
