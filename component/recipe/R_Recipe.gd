extends R_WorldObject
class_name R_Recipe

@export var supported_by_tags: Array[String] = []

@export var input: Array[R_RecipeData] = []
@export var output: R_WorldObject
@export var output_quantity: int = 1

@export var unshaped: bool = false

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

func try_craft(workbench: R_WorldObject, _input: CT_InventorySlot, _output: CT_InventorySlot) -> void:
	var is_supported: bool = false
	for s_tag in supported_by_tags:
		if s_tag in workbench.tags:
			is_supported = true
	
	if not is_supported:
		return
	
	var is_input_supported: bool = false
	
	var input_object: R_WorldObject = _input.get_object()
	if !input_object:
		return
	
	var input_item: CT_ItemStack = _input.get_item_stack()
	
	for data: R_RecipeData in input:
		if data.object == input_object:
			is_input_supported = true
		
		for data_tag in data.tags:
			if data_tag in input_object.tags:
				is_input_supported = true
	
	if not is_input_supported:
		return
	
	var output_item: CT_ItemStack = _output.get_item_stack()
	
	var is_ready_to_craft: bool = _output.is_free()
	
	if output_item:
		if output_item.stackable:
			is_ready_to_craft = output_item.object == output
	
	if is_ready_to_craft:
		input_item.quantity -= 1
		if !output_item:
			output_item = CT_ItemStack.create_from_object(output)
			output_item.quantity = output_quantity
			_output.add_child(output_item)
		else:
			output_item.quantity += output_quantity

static func is_itemstack_has_object_tag(item: CT_ItemStack, tag: String) -> bool:
	if is_instance_valid(item):
		return tag in item.object.tags
	return false

static func is_itemstack_has_object_tag_list(item: CT_ItemStack, tag_list: Array[String]) -> bool:
	if is_instance_valid(item):
		for tag in tag_list:
			if tag in item.object.tags:
				return true
	return false

static func get_itemstack_tags(item: CT_ItemStack) -> Dictionary[String, Variant]:
	if is_instance_valid(item):
		return item.object.tags
	return {}
