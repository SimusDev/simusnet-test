class_name R_PlaceableSettings extends Resource

@export var place_range:float = 5.0

@export_group("Model")
@export var model_mesh:Mesh
@export var model_prefab:PackedScene

@export_group("Color")
@export var correct_color:Color = Color.BLUE
@export var wrong_color:Color = Color.RED

@export_group("Transform")
@export var position:Vector3 = Vector3.ZERO
@export var scale:Vector3 = Vector3.ONE
@export var rotation:Vector3 = Vector3.ZERO

@export_group("CustomSettings")
@export var custom_object:R_WorldObject
@export var custom_shader_material:ShaderMaterial

var object:R_WorldObject
var shader_material:ShaderMaterial = load("res://shaders/placeable.tres")

func _init() -> void:
	if custom_shader_material:
		shader_material = custom_shader_material

func get_object() -> R_WorldObject:
	if custom_object:
		return custom_object
	return object

func get_shader_material() -> ShaderMaterial:
	if custom_shader_material:
		return custom_shader_material
	return shader_material

func get_model() -> Variant:
	if model_mesh:
		return model_mesh
	if model_prefab:
		return model_prefab
	return null
