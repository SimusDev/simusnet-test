@tool
extends ConfirmationDialog


## Path to settings file. Stored as JSON
const SETTINGS_PATH:String = "res://addons/gopilot_assist/settings.json"

const DEFAULT_SETTINGS_PATH:String = "res://addons/gopilot_assist/default_settings.json"

## Stores all settings as a Dictionary
var settings:Dictionary = str_to_var(FileAccess.get_file_as_string(DEFAULT_SETTINGS_PATH))

## Returns original [member settings]
func get_settings() -> Dictionary:
	return settings


## On ready, reads settings from file and writes it to the interface
func _ready() -> void:
	_read_settings_from_file(false)
	_set_interface()
	await get_tree().create_timer(0.1).timeout
	#size.y = 10.0


## Reads file [member SETTINGS_PATH] to [member settings]
## When [param apply_to_interface] is true, applies [member settings] to interface
func _read_settings_from_file(apply_to_interface:bool = true):
	if !FileAccess.file_exists(SETTINGS_PATH):
		create_settings_file()
	_load_settings_file()
	if apply_to_interface:
		_set_interface()


## Creates settings file at [member SETTINGS_PATH]
func create_settings_file():
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE_READ)
	var text := JSON.stringify(settings, "\t")
	file.store_string(text)
	file.close()
	#print("settings: ", settings)
	EditorInterface.get_resource_filesystem().scan()


## Applies all options besides models (see [method set_interface_models]) from [member settings] to the interface
func _set_interface():
	%ShowBuddy.button_pressed = settings["show_buddy"]
	%ShowWelcomeMessage.button_pressed = settings["show_welcome_message"]
	%PrimaryShortcutBtn.text = settings["primary_shortcut"]
	%SecondaryShortcutBtn.text = settings["secondary_shortcut"]
	%ChatShortcutBtn.text = settings["chat_shortcut"]
	%CodeCompletionAbove.value = settings["completion_context_above"]
	%CodeCompletionBelow.value = settings["completion_context_below"]
	%UseMarkdownFormatting.button_pressed = settings["use_markdown_formatting"]
	%UserName.text = settings["user_name"]
	%QueryPrefix.text = settings["query_prefix"]
	%DocumentPrefix.text = settings["document_prefix"]
	%PromptRecommendationsBtn.button_pressed = settings["generate_recommendations"]
	%Pronouns.text = settings["pronouns"]
	%CustomInstructions.text = settings["custom_instructions"]
	%MultilineCompletion.button_pressed = settings["multiline_completion"]


## Reads all the settings from the interface to [member settings]
func _interface_to_variable() -> void:
	# Reads all settings besides models
	settings["show_buddy"] = %ShowBuddy.button_pressed
	settings["show_welcome_message"] = %ShowWelcomeMessage.button_pressed
	settings["primary_shortcut"] = %PrimaryShortcutBtn.text
	settings["secondary_shortcut"] = %SecondaryShortcutBtn.text
	settings["chat_shortcut"] = %ChatShortcutBtn.text
	settings["completion_context_above"] = %CodeCompletionAbove.value
	settings["completion_context_below"] = %CodeCompletionBelow.value
	settings["use_markdown_formatting"] = %UseMarkdownFormatting.button_pressed
	settings["query_prefix"] = %QueryPrefix.text
	settings["document_prefix"] = %DocumentPrefix.text
	settings["generate_recommendations"] = %PromptRecommendationsBtn.button_pressed
	settings["pronouns"] = %Pronouns.text
	settings["custom_instructions"] = %CustomInstructions.text
	settings["multiline_completion"] = %MultilineCompletion.button_pressed
	
	var user_name:String = %UserName.text
	if user_name == "":
		settings["user_name"] = "User"
	else:
		settings["user_name"] = user_name
	EditorInterface.get_resource_filesystem().scan()


## Stores the contents of [member settings] to the settings file defined in [member SEETINGS_PATH] as [JSON]
func _store_settings_to_file() -> void:
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE_READ)
	var text := JSON.stringify(settings, "\t")
	file.store_string(text)
	file.close()
	EditorInterface.get_resource_filesystem().scan()


## Loads the settings file from [member SETTINGS_PATH] to [member settings]
func _load_settings_file():
	if !FileAccess.file_exists(SETTINGS_PATH):
		push_error("No settings file found! Please report!")
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var text := file.get_as_text()
	var data:Dictionary = JSON.parse_string(text)
	for key in data:
		settings[key] = data[key]
	file.close()


## When SettingsWindow is confirmed, reads settings from interface and stores them to [member SETTINGS_PATH]
func _on_confirmed() -> void:
	_interface_to_variable()
	_store_settings_to_file()


func set_setting(key:String, value:Variant):
	settings[key] = value


#func _on_about_to_popup() -> void:
	#size.y = 10.0
