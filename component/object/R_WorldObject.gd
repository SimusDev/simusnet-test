extends R_Object
class_name R_WorldObject

@export var viewmodel: R_ViewModel : get = get_viewmodel

func get_viewmodel() -> R_ViewModel:
	if !viewmodel:
		viewmodel = R_ViewModel.new()
	return viewmodel
