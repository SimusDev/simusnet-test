class_name R_Level extends Resource

@export var code:StringName = "Level"
@export var prefab:PackedScene

@export var icon: Texture

var _instance: LevelInstance

func get_instance() -> LevelInstance:
	return _instance

static var _reference_list:Array[R_Level]
static func get_reference_list() -> Array[R_Level]:
	return _reference_list

func register() -> bool:
	for ref in _reference_list:
		if ref.code == code:
			SimusDev.console.write_error("Unable to register level '%s': level with code '%s' already registred" % [self, code])
			return false
	if _reference_list.has(self):
		SimusDev.console.write_error("Unable to register level '%s': already registred" % [self])
		return false
	_begin_register()
	_reference_list.append(self)
	_registred()
	return true

func unregister() -> bool:
	if not _reference_list.has(self):
		SimusDev.console.write_error("Unable to unregister level '%s': not registred" % [self])
		return false
	_begin_unregister()
	_reference_list.erase(self)
	_unregistred()
	return true

func _begin_register() -> void:pass
func _begin_unregister() -> void:pass
func _registred() -> void:
	SimusDev.console.write_info("Level registred: %s" % [self])
func _unregistred() -> void:
	SimusDev.console.write_info("Level unregistred: %s" % [self])
