@static_unload
#@tool
extends RefCounted
class_name SD_ECS

const METHOD: StringName = "get_ECS"
const META: StringName = "SD_ECS"
const _LOG_NAME: StringName = "[SD_ECS]: %s"

enum PICK_RETURN {
	ARRAY,
	FIRST_VALUE,
	RANDOM_VALUE,
}

static func erase_component(object: Object, component: Variant) -> void:
	var components: Array = get_components_from(object)
	if components.has(component):
		components.erase(component)
	else:
		_debug_log_from_object(object, "doesn't have a component %s" % component, SD_ConsoleCategories.ERROR)

static func try_erase_component(object: Object, component: Variant) -> void:
	var components: Array = get_components_from(object)
	if components.has(component):
		components.erase(component)


static func append_to(object: Object, component: Variant) -> void:
	var components: Array = get_components_from(object)
	if !components.has(component):
		components.append(component)
	else:
		_debug_log_from_object(object, "it already has a component %s" % component, SD_ConsoleCategories.ERROR)

static func try_append_to(object: Object, component: Variant) -> void:
	var components: Array = get_components_from(object)
	if !components.has(component):
		components.append(component)

static func append_to_anyway(object: Object, component: Variant) -> void:
	get_components_from(object).append(component)

static func get_components_from(object: Object) -> Array:
	if !is_instance_valid(object):
		_debug_log_from_object(object, "%s cant get components from null!" % object, SD_ConsoleCategories.ERROR)
		return []
		
	if object.has_method(METHOD):
		var value: Variant = object.call(METHOD)
		if value is Array:
			return value
		_debug_log_from_object(object, "%s must return an Array!" % METHOD, SD_ConsoleCategories.ERROR)
	
	if Engine.is_editor_hint():
		return []
	
	if object.has_meta(META):
		return object.get_meta(META)
	
	var result: Array = []
	object.set_meta(META, result)
	return result

static func find_base_script(script: Script, recursive: bool = true) -> Script:
	if not script:
		return script
	
	var base: Script = script.get_base_script()
	
	if !base:
		return script
	
	if recursive:
		return find_base_script(script.get_base_script())
	return base

static func is_script_extends(script: Script, _extends: Script) -> bool:
	return find_base_script(script) == _extends or script == _extends

static func queue_free_components(from: Object) -> void:
	var components: Array = get_components_from(from)
	for i in components:
		if i is Node:
			i.queue_free()
		components.erase(i)

static func find_components_by_script(from: Object, by: Array[Script], pick: PICK_RETURN = PICK_RETURN.ARRAY) -> Variant:
	var components: Array = get_components_from(from)
	
	var filtered: Array = components.filter(
		func(i: Variant):
			if is_instance_valid(i):
				var is_object: bool = i is Object
				if is_object:
					return by.has(i.get_script()) or by.has(find_base_script(i.get_script()))
			return false
	)
	
	return _return_filtered(filtered, pick)

static func find_components_by_class(from: Object, by: Array[StringName], pick: PICK_RETURN = PICK_RETURN.ARRAY) -> Variant:
	var components: Array = get_components_from(from)
	var filtered: Array = components.filter(
		func(i: Variant):
			return i is Object and by.has(i.get_class())
	)
	
	return _return_filtered(filtered, pick)

static func find_components_by_value(from: Object, by: Array[Variant], pick: PICK_RETURN = PICK_RETURN.ARRAY) -> Variant:
	var components: Array = get_components_from(from)
	var filtered: Array = components.filter(func(i: Variant):
		return by.has(i)
		)
	
	return _return_filtered(filtered, pick)

static func _return_filtered(filtered: Array, pick: PICK_RETURN) -> Variant:
	if pick == PICK_RETURN.ARRAY:
		return filtered
	
	if !filtered.is_empty():
		if pick == PICK_RETURN.FIRST_VALUE:
			return filtered[0]
		if pick == PICK_RETURN.RANDOM_VALUE:
			return filtered.pick_random()
	
	return null

static func find_first_component_by_script(from: Object, by: Array[Script]) -> Variant:
	return find_components_by_script(from, by, PICK_RETURN.FIRST_VALUE)

static func find_first_component_by_class(from: Object, by: Array[StringName]) -> Variant:
	return find_components_by_class(from, by, PICK_RETURN.FIRST_VALUE)

static func find_first_component_by_value(from: Object, by: Array[Variant]) -> Variant:
	return find_components_by_value(from, by, PICK_RETURN.FIRST_VALUE)

static func _debug_log_from_object(object: Object, text: Variant, category: int) -> SD_ConsoleMessage:
	return SD_Console.i().write_from_object(object, _LOG_NAME % text, category)

static func node_find_above_by_script(from: Node, script: Script) -> Node:
	if find_base_script(from.get_script()) == script or from.get_script() == script:
		return from
	
	if from == SimusDev.get_tree().root:
		return null
	
	return node_find_above_by_script(from.get_parent(), script)

static func node_find_above_by_component(from: Node, component: Script) -> Node:
	var founded = find_first_component_by_script(from, [component])
	if founded:
		return founded
	
	if from == SimusDev.get_tree().root:
		return null
	
	return node_find_above_by_component(from.get_parent(), component)

static func node_find_above_by_class(from: Node, classname: String) -> Node:
	if from.get_script():
		if from.get_script() is Script:
			if from.get_script().get_global_name() == classname:
				return from
	
	if from.get_class() == classname:
		return from
	
	if from == SimusDev.get_tree().root:
		return null
	
	return node_find_above_by_class(from.get_parent(), classname)


static func find_children_by_script(node: Node, script: Script, recursive: bool = true) -> Array[Node]:
	var result: Array[Node] = []
	_find_children_by_script_internal(result, node, script, recursive)
	return result

static func find_children_by_scripts(node: Node, scripts: Array[Script], recursive: bool = true) -> Array[Node]:
	var result: Array[Node] = []
	for script in scripts:
		_find_children_by_script_internal(result, node, script, recursive)
	return result

static func _find_children_by_script_internal(array: Array[Node], node: Node, script: Script, recursive: bool = true) -> void:
	for child in node.get_children():
		if is_script_extends(child.get_script(), script):
			array.append(child)
		
		_find_children_by_script_internal(array, child, script, recursive)

static func find_children_by_class(node: Node, name: String, recursive: bool = true) -> Array[Node]:
	var result: Array[Node] = []
	_find_children_by_class_internal(result, node, name, recursive)
	return result

static func find_children_by_classes(node: Node, names: Array[String], recursive: bool = true) -> Array[Node]:
	var result: Array[Node] = []
	for name in names:
		_find_children_by_class_internal(result, node, name, recursive)
	return result

static func _find_children_by_class_internal(array: Array[Node], node: Node, name: String, recursive: bool = true) -> void:
	for child in node.get_children():
		if child.get_class() == name:
			array.append(child)
		
		_find_children_by_class_internal(array, child, name, recursive)
