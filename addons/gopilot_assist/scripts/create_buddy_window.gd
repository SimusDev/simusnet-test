@tool
extends ConfirmationDialog

var COMMON := preload("res://addons/gopilot_utils/scripts/common.gd").new()

const DEFAULT_BUDDY_SCENE := preload("res://addons/gopilot_assist/buddies/default_buddy/default_buddy.tscn")
const BUDDY_DIR := "res://addons/gopilot_assist/buddies/"

func _ready() -> void:
	%SliderValue.text = str(snappedf(%TemperatureSlider.value, 0.1))


var editing_buddy:bool = false

func edit_buddy(buddy_name:String):
	var dir := DirAccess.open(BUDDY_DIR + buddy_name)
	if buddy_name + ".tres" not in dir.get_files():
		# When no resource file is found, abort
		return
	editing_buddy = true
	popup()
	ok_button_text = "Save Changes"
	var buddy:GopilotBuddy = load(BUDDY_DIR + buddy_name + "/" + buddy_name + ".tres")
	%Name.text = buddy.name
	%SysmtePrompt.text = buddy.system_prompt
	%Model.text = buddy.model
	%OverrideTemperatureBtn.button_pressed = buddy.use_custom_temperature
	%TemperatureSlider.value = buddy.custom_temperature
	%BuddyPath.text = buddy.buddy.resource_path
	_buddy_scene_selected(buddy.buddy.resource_path)
	


func _on_browse_buddies_btn_pressed() -> void:
	%ChoseBuddyDialog.popup()


func _buddy_scene_selected(path: String) -> void:
	var scene:PackedScene = load(path)
	if %BuddyCon.get_child_count() != 0:
		for child in %BuddyCon.get_children():
			child.queue_free()
	%BuddyCon.add_child(scene.instantiate())
	%BuddyPath.text = path


func _on_create_buddy_scene_btn_pressed() -> void:
	if %Name.text.is_empty():
		set_warning("No name was set!")
		return
	var scene_path:String = BUDDY_DIR +  %Name.text.to_snake_case() + ".tscn"
	if FileAccess.file_exists(scene_path):
		set_warning("Scene '" + scene_path + "' already exists! Chose a different name")

	set_warning()
	%BuddyCreationInfo.popup()


func _on_info_btn_pressed() -> void:
	%BuddyInfo.popup()


func _on_buddy_creation_info_confirmed() -> void:
	var inherited_scene := COMMON.create_inherited_scene(DEFAULT_BUDDY_SCENE, %Name.text)
	var buddy_snake:String= %Name.text.to_snake_case()
	# Create buddy folder if it doesn't exist already
	if !DirAccess.dir_exists_absolute(BUDDY_DIR + buddy_snake):
		DirAccess.make_dir_absolute(BUDDY_DIR + buddy_snake)
	var scene_path:String = BUDDY_DIR + %Name.text.to_snake_case() + "/" + buddy_snake + ".tscn"
	ResourceSaver.save(inherited_scene, scene_path)
	EditorInterface.open_scene_from_path(scene_path)
	hide()
	EditorInterface.get_resource_filesystem().scan()


func set_warning(warning:String = ""):
	if warning.is_empty():
		%Warning.hide()
		return
	%Warning.text = warning
	%Warning.show()


func _on_temperature_slider_value_changed(value: float) -> void:
	%SliderValue.text = str(snappedf(value, 0.1))


func _on_override_temperature_btn_toggled(toggled_on: bool) -> void:
	%TemperatureSlider.editable = toggled_on


## Creates the file for the buddy
func _on_confirmed() -> void:
	var buddy := GopilotBuddy.new()
	buddy.name = %Name.text
	buddy.custom_temperature = %TemperatureSlider.value
	buddy.use_custom_temperature = %OverrideTemperatureBtn.button_pressed
	buddy.system_prompt = %SysmtePrompt.text
	buddy.buddy = load(%BuddyPath.text)
	var buddy_snake:String = %Name.text.to_snake_case()
	# Create buddy folder if it doesn't exist already
	if !DirAccess.dir_exists_absolute(BUDDY_DIR + buddy_snake):
		DirAccess.make_dir_absolute(BUDDY_DIR + buddy_snake)
	ResourceSaver.save(buddy, BUDDY_DIR + buddy_snake + "/" + buddy_snake + ".tres")
	editing_buddy = false


func _on_about_to_popup() -> void:
	if editing_buddy:
		return
	ok_button_text = "Create"
	cancel_button_text = "Cancel"
	%SysmtePrompt.text = ""
	%Name.text = ""
	%BuddyPath.text = ""
	%TemperatureSlider.value = 0.7
	%OverrideTemperatureBtn.button_pressed = false


func _on_idle_btn_pressed() -> void:
	%BuddyCon.get_child(0).get_node("Anim").play("idle")


func _on_talk_btn_pressed() -> void:
	%BuddyCon.get_child(0).get_node("Anim").play("talk")
