@tool
extends Window


func set_config(config:Dictionary) -> void:
	var providers := _get_providers()
	var current_provider:int = -1
	var i:int = 0
	%Providers.clear()
	for provider in providers:
		if provider == config["provider"]:
			current_provider = i
		%Providers.add_item(provider)
		i += 1
	if current_provider != -1:
		%Providers.select(current_provider)
	%Host.text = config["host"]
	%Port.value = config["port"]
	%Key.text = config["api_key"]
	%ModelName.text = config["model"]
	%Temperature.value = config["temperature"]
	%Temperature.visible = config["override_temperature"]
	%OverrideTemperature.button_pressed = config["override_temperature"]


func _get_providers() -> PackedStringArray:
	var providers:PackedStringArray = []
	const PROVIDER_DIR := "res://addons/gopilot_utils/api_providers"
	for file in DirAccess.get_files_at(PROVIDER_DIR):
		if file.ends_with(".gd"):
			providers.append(file.trim_suffix(".gd"))
	return providers


func get_config() -> Dictionary:
	var config := {}
	config["provider"] = %Providers.get_item_text(%Providers.selected)
	config["host"] = %Host.text
	config["port"] = %Port.value
	config["api_key"] = %Key.text
	config["model"] = %ModelName.text
	config["override_temperature"] = %OverrideTemperature.button_pressed
	config["temperature"] = %Temperature.value
	return config


const DEFAULT_CONFIG := {
	"provider": "ollama",
	"host": "http://127.0.0.1",
	"port": 11434,
	"api_key": "",
	"model": "llama3.2",
	"override_temperature": false,
	"temperature": 0.7
}


func configure_model(_model:String):
	popup_centered()
	edited_model = _model
	if edited_model not in get_parent().settings:
		push_warning("Gopilot Settings: Could not find model '", edited_model, "' under settings. Applying default config")
	else:
		set_config(get_parent().settings[edited_model])


var edited_model:String = ""


func _on_confirmed() -> void:
	if edited_model.is_empty():
		return
	get_parent().settings[edited_model] = get_config()
	edited_model = ""


func _on_canceled() -> void:
	edited_model = ""
	pass # Replace with function body.


func _on_providers_item_selected(index: int) -> void:
	var provider:String = %Providers.get_item_text(index)
	var provider_handler:GopilotApiHandler = load("res://addons/gopilot_utils/api_providers/" + provider + ".gd").new()
	var defaults := provider_handler._get_default_properties()
	if defaults.has("host"):
		%Host.text = defaults["host"]
	if defaults.has("port"):
		%Port.value = defaults["port"]
	if defaults.has("api_key"):
		%Key.text = defaults["api_key"]
	if defaults.has("model"):
		%ModelName.text = defaults["model"]
