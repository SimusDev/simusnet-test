@tool
@icon("res://addons/gopilot_utils/textures/chat_requester_icon.svg")
extends Node
class_name ChatRequester
##@tutorial(Video Tutorial): https://youtu.be/6xLmb8PtRro
## A Node used to communicate with [b]ollama[/b] and other LLM APIs.
## Use [method send_message] and [method start_generation] afterwards!
## Connect the [signal message_end] signal for simple use
## [codeblock]
## extends Node
## @onready var chat := $ChatRequester
## 
## func _ready():
##    var message := "Why is the sky blue?"
##    chat.send_message(message)
##    chat.start_respopnse()
##    chat.new_word.connect(_new_word_received)
## 
## # Prints the newly generated word
## func _new_word_received(word:String):
##    print(word)
## [/codeblock]

## The script which sends and receives requests. Don't modify this directly, use the [member provider] dropdown or the [method set_provider] method instead
var api_script:GopilotApiHandler = preload("res://addons/gopilot_utils/api_providers/ollama.gd").new()

@export_storage var _api_gdscript:GDScript = preload("res://addons/gopilot_utils/api_providers/ollama.gd")


## API provider used for sending requests[br]
## If you use your own API script, have a look at the default at "res://addons/gopilot_utils/api_providers/ollama.gd", duplicate it with a different name, and modify it accordingly
@export var provider:String = "ollama"

@export_custom(PROPERTY_HINT_PASSWORD, "") var api_key:String = ""
## Host to connect to[br]
## If you are running ollama on your local machine, keep this as is
@export var host:String = "http://127.0.0.1"
## Port to the API connection[br]
## If you are running ollama on your local machine, keep this as is
@export var port:int = 11434
## Model to use for generation
@export var model:String = "llama3.2"
## [b]Temperature[/b], or [b]"creativity"[/b]. Keep low (around 0.1 and 0.2) for [b]consistent and stable generations[/b].
@export_range(-0.01, 2.0, 0.01) var temperature:float = -0.01
## Used for modifying the models character. You can make it act as a generic assistant, a pirate, a dog and many more! Give it a try!
@export_multiline var system_prompt:String = "Keep your answers short!"
## Additional options to be passed to the generation[br]
## Example options: [param seed], [param frequency_penalty], [param stop], [param num_ctx]
@export var options:Dictionary = {}
## Boring stuff. Don't use this unless you are getting errors
@export var automatically_add_messages:bool = true

## Automatically reconnect to the host when a request is made[br]
## Activate if you get "STATUS != STATUS_CONNECTED" error
#@export var reconnect_on_request:bool = false

## When this and [member reconnect_on_request] true, will emit [signal disconnected_from_host] on every request
@export var emit_disconnect_signal_on_request:bool = false

## How long the requester is trying to reconnect until giving up
@export var reconnection_timeout:float = 3.0

@export_group("Debug")
## Show what exactly how the conversation between you and the assistant goes on in the console
@export var debug_mode:bool = false:
	set(new):
		debug_mode = new
		_ready()

## The content of the conversation. Looks like this:[br]
## [codeblock]
## [
##    {
##        "role":"user",
##        "content":"Why is the sky blue?"
##    },
##    {
##        "role":"assistant",
##        "content":"It's blue because of the sun or something"
##    },
##    {
##        "role":"tool",
##        "content":"some json tool call here"
##    }
## ]
## [/codeblock]
@onready var conversation:Array[Dictionary]

## Internal variable. 
var client:HTTPClient
## Internal variable. 
var connected = false

## Emitted when the first token was generated
signal message_start
## Emitted whenever the model generates a new token (word or word-chunk). Contains the generated token[br]
## In this example, we use the signal to receive live updates every time a new token is generated[br]
## [codeblock]
## var response_label:Label = $ResponseLabel
## var chat_requester:CharRequester = $ChatRequester
## 
## func _ready() -> void:
##    var prompt:String = "Make a bullet point list of the most popular LLM API providers"
##    chat_requester.generate(prompt)
##    chat_requester.new_word.connect(_on_new_word)
##
## # Each new token is immediately added to the label
## func _on_new_word(word:String) -> void
##    response_label.text += word
## [/codeblock]
signal new_word(word:String)
## Emitted when the model finishes its generation. Contains the entire generated message
signal message_end(full_message:String)
## Emitted when the Node connects to the API host
signal connected_to_host
## Emitted when the Node disconnects from the API host. For example when calling [param reconnect()]
signal disconnected_from_host


func _set(property: StringName, value: Variant) -> bool:
	if property == "connected":
		push_error("ChatRequester Error: 'connected' is a read-only variable. It cannot be changed by other scripts")
		return true
	if property == "conversation":
		push_error("ChatRequester Error: 'conversation' must be set using 'set_conversation' method")
		return true
	return false


func _ready():
	if !new_word.is_connected(_on_new_word):
		new_word.connect(_on_new_word)
	if !message_end.is_connected(_on_message_end):
		message_end.connect(_on_message_end)
	if _api_gdscript:
		api_script = _api_gdscript.new()
	else:
		push_error("ChatRequester: #api_script' is not set. Make sure you selected an API type in the inspector")
		return
	set_system_prompt(system_prompt)
	client = HTTPClient.new()
	var err = client.connect_to_host(host, port)
	assert(err == OK)
	set_provider(provider)


## Internal function. Use [method set_api_provider] instead
func set_api_script(script:GDScript, apply_default_values:bool = true) -> void:
	_api_gdscript = script
	var api:GopilotApiHandler = script.new()
	api_script = api
	api_script.chat_requester = self
	var property_overrides:Dictionary = api_script._get_default_properties()
	if apply_default_values:
		for property in property_overrides:
			set(property, property_overrides[property])
	notify_property_list_changed()


## Sets the [memeber provider], [member _api_gdscript] and [member api_script][br]
## If you want to use your own provider, refer to [member provider]
func set_provider(_provider:String = "ollama", apply_default_values:bool = false) -> void:
	
	if FileAccess.file_exists(API_PROVIDERS_DIR + "/" + _provider + ".gd"):
		_api_gdscript = load(API_PROVIDERS_DIR + "/" + _provider + ".gd")
		set_api_script(_api_gdscript, apply_default_values)
		api_script.chat_requester = self
		api_script.http_client = client
		provider = _provider
	else:
		printerr("ChatRequester: Provider '" + _provider + "' not found. Make sure it exists in '" + API_PROVIDERS_DIR + "'")


## Applies a [Dictionary] config to the [ChatRequester]. Can be used to store settings in bulk[br]
## Generally, every property name can be passed as a key and the value will then be assigned to the [ChatRequester].
func apply_config(config:Dictionary):
	#print("applying config: ", config)
	var must_reconnect:bool = config.has("host") and config["host"] != host
	for key in config:
		if key == "provider":
			set_provider(config["provider"])
		elif key == "temperature":
			if config.has("override_temperature"):
				if config["override_temperature"]:
					set(key, config[key])
				else:
					set(key, -0.01)
		elif key == "override_temperature":
			# Does nothing. Only used for the above condition
			pass
		else:
			set(key, config[key])
	if must_reconnect:
		reconnect()


## Converts the [ChatRequester] to a [Dictionary]. Useful for saving settings[br]
## Returned dictionary looks like this[br]
## [codeblock]
## {
##     "provider": "ollama",
##     "host": "localhost",
##     "port": 1143,
##     "model": "llama2",
##     "api_key": ""
##     "temperature": -0.01
## }
## [/codeblock]
func get_config() -> Dictionary:
	var config := {
		"provider": provider,
		"host": host,
		"port": port,
		"model": model,
		"api_key": api_key,
		"temperature": temperature
	}
	return config


func _physics_process(delta: float) -> void:
	# Always poll the client to update its state
	client.poll()
	
	# Handle connection status updates
	if client.get_status() == HTTPClient.STATUS_CONNECTING || client.get_status() == HTTPClient.STATUS_RESOLVING:
		if !connected:
			if debug_mode:
				print("Connecting...")
	elif client.get_status() == HTTPClient.STATUS_CONNECTED:
		if !connected:
			connected = true
			if debug_mode:
				print("\tConnected to host '", host, "'")
			connected_to_host.emit()
	elif client.get_status() == HTTPClient.STATUS_DISCONNECTED:
		if connected:
			connected = false
			if debug_mode:
				print("Disconnected!")
			disconnected_from_host.emit()
	
	
	if client.get_status() == HTTPClient.STATUS_BODY:
		if client.has_response():
			var chunk = client.read_response_body_chunk()
			if chunk.size() > 0:
				_process_chunk(chunk.get_string_from_utf8())


## Forwards string API chunks to the API script for processing[br]
## See more on [GopilotApiHandler]
func _process_chunk(chunk: String):
	api_script._handle_incoming_package(chunk)

##@deprecated
## Fallback version of [method fill_in_the_middle], in case your model doesn't support it[br]
## DO NOT USE THIS! Will be removed in future version
func fill_in_the_middle_fallback(before:String, stream:bool = false, ) -> String:
	if not await _ensure_connection():
		return ""
	options["stop"] = ["```"]
	const LENGTHEN_PRT := "Please extend the code in a logical and sensible way:\n```gdscript\n{.code}\n```"
	generate(LENGTHEN_PRT, stream, false, false, "You are an integrated AI assistant in the Godot 4 Game Engine. Always use best practices when writing GDSCript", "```gdscript\n" + before)
	options.erase("stop")
	return await message_end


## Performs [b]fill-in-the-middle[/b] request to the API script[br]
## This uses the model-specific fill-in-the-middle support. The chosen model MUST support this operation for the method to work
func fill_in_the_middle(before:String, after:String, stream:bool = false) -> String:
	if not await _ensure_connection():
		return ""
	api_script._send_fill_in_the_middle_request(before, after, stream)
	return await message_end


## Invernal method. Do not call!
func _on_new_word(new_word:String):
	if response[0].is_empty():
		message_start.emit()
	response[0] += new_word


## Internal method. Do not call!
func _on_message_end(full_message:String):
	_finalize_response()

## Halts the generation of tokens[br]
## when [param emit_signal] is false, the [signal message_end] signal will not be emitted
func stop_generation(emit_reconnect_signal:bool = true, emit_message_end_signal:bool = true):
	if response[0] != "" and automatically_add_messages:
		conversation.append({"role":"assistant", "content":response[0]})
	response = [""]
	reconnect(emit_reconnect_signal, emit_message_end_signal)

#region Helper functions
## Internal method. Do not call!
func _append_response(word: String):
	response[0] += word

## Internal method. Do not call!
func _finalize_response():
	if automatically_add_messages:
		send_message(response[0], chat_role.ASSISTANT)
	response = [""]
#endregion

## Disconnects and reconnects to the server[br]
## when [param emit_signal] is true, the [signal disconnected_from_host] signal will be emitted
func reconnect(emit_disconnected_signal:bool = true, emit_message_end_signal:bool = true) -> void:
	if debug_mode:
		print("Reconnecting to the API...")
	connected = false
	if emit_disconnected_signal:
		disconnected_from_host.emit()
	client.close()
	if debug_mode:
		print("\tClosed connection...")
	client.connect_to_host(host, port)
	if debug_mode:
		print("\tReconnecting...")
	if emit_message_end_signal:
		message_end.emit(response[0])


## Sends a message to the API provider and generates an answer to the [param prompt][br]
## When [param stream] true, the [signal new_word] signal will be emitted every time there is an update[br]
## When [param format_json] is true, the model generates its response in JSON format[br]
## When [param raw] is true, the model performs a raw text prediction. This does not supprt [param system][br]
## The [param system] is passed as the system prompt to the model
func generate(prompt:String, stream:bool=true, format_json:bool=false, raw:bool=false, system:String=system_prompt, prefix:String="") -> String:
	if not await _ensure_connection():
		return ""
	if raw:
		api_script._send_raw_completion_request(prompt, stream)
		return await message_end
	var conv:Array[Dictionary] = [
		{"role":"system", "content":system},
		{"role":"user", "content":prompt}
	]
	if prefix:
		conv.append({"role":"assistant", "content":prefix})
	api_script._send_conversation_request(
		conv.duplicate(true),
		stream,
		format_json
	)
	var response:String = await message_end
	return response


## Different roles for the conversation messages in the [method send_message] method
enum chat_role {
	USER,		## The usual user role, used for you! The user!
	ASSISTANT,	## Assitant role, this is the role used for what the assistant responds with. Can be used to make the assistant "think" it said something, even though it actually didn't
	SYSTEM,		## Role for the system prompt. Depending on the model, this can function as a tool-retrieval role
	TOOL		##@deprecated[br]Tool retrieval role, only supported by some models
}


## Does not modify [member conversation] and uses [param _conversation] instead for chat-generation[br]
## When [param stream] is true, the API returns updates each time a new token is generated, which can be cought using the [signal new_word][br]
## Set [param format_json] to true, to let the model generate its response in JSON
func generate_with_conversation(_conversation:Array[Dictionary], stream:bool=true, format_json:bool=false) -> String:
	if not await _ensure_connection():
		return ""
	api_script._send_conversation_request(_conversation.duplicate(true), stream, format_json)
	return await message_end


## Appends a message to the [member conversation] and starts generation if [param start_generation] is true.
func send_message(msg:String, role:chat_role = chat_role.USER, start_generation:bool = false) -> String:
	var role_name:String
	match role:
		chat_role.USER: role_name = "user"
		chat_role.ASSISTANT: role_name = "assistant"
		chat_role.SYSTEM: role_name = "system"
		chat_role.TOOL: role_name = "tool"
		_:
			push_error("Non supported role! Quitting")
			return "ERROR! Look in console"
	conversation.append(
		{
			"role" : role_name,
			"content" : msg
		}
	)
	if start_generation:
		start_response()
		return await message_end
	else:
		return "ONLY RETURNS MESSAGE WHEN 'start_generation' is true!"


## Sets the system prompt in the [member conversation][br]
## Always places the [param system] prompt at the beginning of the [member conversation]
func set_system_prompt(system:String) -> void:
	system_prompt = system
	if conversation.size() > 0:
		if conversation[0]["role"] == "system":
			conversation[0]["content"] = system
		else:
			conversation.insert(0, {"role":"system", "content":system})
	else:
		conversation.append({"role":"system", "content":system})


## Returns original [member conversation][br]
## Every change you make to the returned conversation will also be made in the original conversation (in the ChatRequester)
func get_conversation() -> Array[Dictionary]:
	return conversation


## Returns an array of available models[br]
func get_models() -> PackedStringArray:
	if not await _ensure_connection():
		return []
	return await api_script._get_models()


## Replaces [member conversation] with the provided [param _conversation]
func set_conversation(_conversation:Array[Dictionary]) -> void:
	conversation = _conversation


## Clears the [member conversation][br]
## If [param keep_system_prompt] is set to `true`, the system prompt will be kept in the first message of the conversation
func clear_conversation(keep_system_prompt:bool = true) -> void:
	conversation = []
	if keep_system_prompt:
		conversation = [{"role":"system", "content":system_prompt}]


## Internal variable! Used to store the intermediate generation
var response:Array = [""]


## API Providers[br]
## Directory where API provider scripts are stored[br]
## To find out how to add your own providers, look at [GopilotApiHandler]
const API_PROVIDERS_DIR := "res://addons/gopilot_utils/api_providers"


## Returns a list of available API providers[br]
## Each API provider is a separate file in the [member API_PROVIDERS_DIR] directory[br]
func get_api_providers() -> PackedStringArray:
	var providers:PackedStringArray = []
	for file in DirAccess.get_files_at(API_PROVIDERS_DIR):
		if file.ends_with(".gd"):
			providers.append(file.trim_suffix(".gd"))
	return providers


## Begins the generation proccess after [member conversation] is filled with conversation data[br]
## For filling the [member conversation], use [method send_message] or [method set_conversation][br]
## [param format_json] Prompts the LLM to generate its response in JSON[br]
## [param prefix] Adds a prefix to the assistant's response[br], allowing for more controllabble generation[br]
## [param stream] Enables streaming of the response[br], allowing for real-time updates
func start_response(format_json:bool=false, prefix:String="", stream:bool = true):
	if not await _ensure_connection():
		return
	if conversation[-1]["role"] == "assistant":
		if prefix != "":
			conversation[-1]["content"] = prefix
	elif !prefix.is_empty():
		conversation.append({"role":"assistant", "content":prefix})
	api_script._send_conversation_request(conversation.duplicate(true), stream, format_json)
	response = [""]


func _ensure_connection() -> bool:
	var time_elapsed:float = 0.0
	client.poll()
	if client.get_status() != client.STATUS_CONNECTED:
		reconnect(emit_disconnect_signal_on_request, false)
		while true:
			client.poll()
			if client.get_status() == client.STATUS_CONNECTED:
				break
			await get_tree().create_timer(0.01).timeout
			time_elapsed += 0.01
		if time_elapsed >= reconnection_timeout:
			return false
	return true
