extends GopilotApiHandler


signal models_found(query:Dictionary)

func _get_default_properties() -> Dictionary:
	return {
		"port":11434,
		"host":"http://127.0.0.1",
		"model":"llama3.2"
	}


func _send_raw_completion_request(prefix:String, streaming:bool) -> void:
	var query := {
		"model":chat_requester.model,
		"prompt":prefix,
		"stream":streaming,
		"options":{}
	}
	if chat_requester.temperature != -0.01:
		query["options"]["temperature"] = chat_requester.temperature
	for option in chat_requester.options:
		query["options"].append({option:chat_requester.options[option]})
	http_client.request(HTTPClient.METHOD_POST, "/api/generate", [], JSON.stringify(query))


func _send_fill_in_the_middle_request(prefix:String, suffix:String, streaming:bool) -> void:
	var query := {
		"model":chat_requester.model,
		"prompt":prefix,
		"suffix":suffix,
		"stream":streaming,
		"options":{}
	}
	if chat_requester.temperature != -0.01:
		query["options"]["temperature"] = chat_requester.temperature
	for option in chat_requester.options:
		query["options"][option] = chat_requester.options[option]
	http_client.request(HTTPClient.METHOD_POST, "/api/generate", [], JSON.stringify(query))

func _send_conversation_request(conversation:Array[Dictionary], streaming:bool, json_mode:bool) -> void:
	var query := {
		"model":chat_requester.model,
		"messages":conversation,
		"stream":streaming,
		"options":{}
	}
	if json_mode:
		query["format"] = "json"
	if chat_requester.temperature != -0.01:
		query["options"]["temperature"] = chat_requester.temperature
	for option in chat_requester.options:
		query["options"][option] = chat_requester.options[option]
	#print(JSON.stringify(query))
	http_client.request(HTTPClient.METHOD_POST, "/api/chat", ["Content-Type: application/json"], JSON.stringify(query))


func _handle_incoming_package(package:String):
	#print("Package: ", package)
	var json:Dictionary = JSON.parse_string(package)
	if json.has("models"):
		models_found.emit(json)
		return
	if json.has("message") and json["message"].has("content"):
		if json["done"] == true:
			emit_message_end(json["message"]["content"])
			return
		#print("emitting: ", json["message"]["content"])
		emit_new_word(json["message"]["content"])
	if json.has("response"):
		var new_token:String = json["response"]
		if new_token.is_empty():
			return
		emit_new_word(json["response"])


func _get_models():
	http_client.poll()
	http_client.request(HTTPClient.METHOD_GET, "/api/tags", [])
	var json_response:Dictionary = await models_found
	var model_names:PackedStringArray = []
	#print(json_response)
	var models:Array = json_response["models"]
	for object in models:
		#print("Found new model")
		model_names.append(object["name"])
	return model_names


func _get_hidden_properties():
	return [
		"api_key",
		]
