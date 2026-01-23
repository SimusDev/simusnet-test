extends R_WorldObject
class_name R_Recipe

@export var input: Array[R_RecipeData] = []
@export var output: R_WorldObject
@export var output_quantity: int = 1

static var _recipes: Dictionary[String, R_Recipe]

static func get_group() -> String:
	return "recipe"

static func get_recipe_list() -> Array[R_Recipe]:
	return _recipes.values()

static func find_by_id(value: String) -> R_Recipe:
	return _recipes.get(value)

func _registered() -> void:
	super()
	_recipes[id] = self

func _unregistered() -> void:
	super()
	_recipes.erase(id)
