extends R_Object
class_name R_WorldObject

@export var viewmodel: R_ViewModel : get = get_viewmodel



func _registered() -> void:
	super()

func _unregistered() -> void:
	super()

func get_entity_script() -> GDScript:
	return null

func get_viewmodel() -> R_ViewModel:
	if !viewmodel:
		viewmodel = R_ViewModel.new()
	return viewmodel
