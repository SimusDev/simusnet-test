extends R_WorldObject
class_name R_Entity

static var _entities: Dictionary[String, R_Entity]

static func get_entity_list() -> Array[R_Entity]:
	return _entities.values()

static func find_by_id(value: String) -> R_Entity:
	return _entities.get(value)

func _registered() -> void:
	super()
	_entities[id] = self

func _unregistered() -> void:
	super()
	_entities.erase(self)
