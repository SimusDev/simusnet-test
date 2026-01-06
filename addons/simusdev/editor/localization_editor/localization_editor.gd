@tool
class_name SD_EditorUILocalization extends Control

signal resource_changed

var sections:Dictionary[String, String]

@export var resource:SD_LocalizationResource : set = set_resource, get = get_resource
func set_resource(new_res:SD_LocalizationResource) -> void:
	resource = new_res
	resource_changed.emit()
func get_resource() -> SD_LocalizationResource:
	return resource

@onready var language_sections: HBoxContainer = $Languages/HBoxContainer
@onready var text_edit: TextEdit = $TextEdit


func _ready() -> void:
	pass

func _load_file(path:String) -> void:
	var new_res = load(path)
	if new_res is SD_LocalizationResource:
		resource = new_res
		_parse_resource_data()

func _parse_resource_data() -> void:
	var _languages:PackedStringArray = detect_languages(resource)
	for lang in _languages:
		sections.get_or_add(lang, get_section_body(resource, lang))
	
	for c in language_sections.get_children():
		language_sections.remove_child(c)
		c.queue_free()
	
	for key in sections.keys():
		var section_btn:SD_EditorUILanguageSectionButton = SD_EditorUILanguageSectionButton.new()
		section_btn.section = key
		section_btn.pressed.connect(_select_section.bind(section_btn.section))
		language_sections.add_child(section_btn)

func _select_section(section:String) -> void:
	text_edit.text = sections.get(section)

static func get_resource_data(res:SD_LocalizationResource) -> String:
	return res.DATA

static func get_section_body(res: SD_LocalizationResource, lang: String) -> String:
	var lines := res.DATA.split("\n")
	var result_lines := PackedStringArray()
	var is_reading := false

	for line in lines:
		line = line.strip_edges()
		if line.is_empty():
			continue
			
		if line.begins_with("[") and line.ends_with("]"):
			if line == lang:
				is_reading = true
				continue
			elif is_reading:
				break
		
		if is_reading:
			result_lines.append(line)
			
	return "\n".join(result_lines)

static func detect_languages(res:SD_LocalizationResource) -> PackedStringArray:
	var result_sections:PackedStringArray = []
	for line:String in res.DATA.split("\n"):
		if line.is_empty():
			continue
		if line.begins_with("[") and line.ends_with("]"):
			result_sections.append(line)
	
	return result_sections
