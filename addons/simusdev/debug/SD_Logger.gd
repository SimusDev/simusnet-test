extends RefCounted
class_name SD_Logger

var _name: String

var _console: SD_TrunkConsole

func _init(name: Variant) -> void:
	_console = SimusDev.console
	_name = str(name)
	
	if name is Object:
		_name = name.get_class()
		if name.get_script():
			_name = name.get_script().get_global_name()
		if name is Node:
			_name += ", " + str(name)
	
	

static func variant_to_string(variant: Variant) -> String:
	if variant is Object:
		var parsed: String = "%s (%s)"
		var classname: String = variant.get_class()
		var objectname: String = str(variant)
		if variant.get_script():
			classname = variant.get_script().get_global_name()
		if variant is Node:
			objectname = str(variant.get_path())
		
		return parsed % [objectname, classname]
		
	return str(variant)

func debug(message: Variant, category: int = 0) -> SD_ConsoleMessage:
	return _console.write("[%s]: %s" % [_name, message], category)
