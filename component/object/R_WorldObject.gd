extends R_Object
class_name R_WorldObject

@export var viewmodel: R_ViewModel : get = get_viewmodel

static var _world_objects: Dictionary[String, R_WorldObject]

static func get_world_object_list() -> Array[R_WorldObject]:
	return _world_objects.values()

static func find_by_id(value: String) -> R_WorldObject:
	return _world_objects.get(value)

static func find_in(node: Node) -> R_WorldObject:
	if node.has_meta("R_WorldObject"):
		return node.get_meta("R_WorldObject")
	return null

func set_in(node: Node) -> void:
	node.set_meta("R_WorldObject", self)

func _registered() -> void:
	super()
	_world_objects[id] = self

func _unregistered() -> void:
	super()
	_world_objects.erase(id)

func get_viewmodel() -> R_ViewModel:
	if !viewmodel:
		viewmodel = R_ViewModel.new()
	return viewmodel
