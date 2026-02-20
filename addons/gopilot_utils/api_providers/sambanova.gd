extends GopilotApiHandler


signal models_found(query: Dictionary)


func _get_default_properties() -> Dictionary:
	return {
		"port": 443,
		"host": "https://api.sambanova.ai",
		"model": "Qwen2.5-Coder-32B-Instruct"
	}


func _send_conversation_request(conversation: Array[Dictionary], streaming: bool, json_mode: bool) -> void:
	var query := {
		"model": chat_requester.model,
		"messages": conversation,
		"stream": streaming,
	}
	if chat_requester.temperature != -0.01:
		query["temperature"] = chat_requester.temperature
	for option in chat_requester.options:
		query[option] = chat_requester.options[option]
	if conversation[-1]["role"] == "assistant":
		query["messages"][-1]["prefix"] = true
	
	var headers := [
		"Authorization: Bearer %s" % chat_requester.api_key,
		"Content-Type: application/json",
		"Accept: application/json"
	]
	http_client.request(HTTPClient.METHOD_POST, "/v1/chat/completions", headers, JSON.stringify(query))


func _send_fill_in_the_middle_request(prefix: String, suffix: String, streaming: bool) -> void:
	var query := {
		"model": chat_requester.model,
		"prompt": prefix,
		"suffix": suffix,
		"stream": streaming,
	}
	
	# Add temperature and other options if provided
	if chat_requester.temperature != -0.01:
		query["temperature"] = chat_requester.temperature
	for option in chat_requester.options:
		query[option] = chat_requester.options[option]
	
	var headers := ["Authorization: Bearer %s" % chat_requester.api_key, "Content-Type: application/json"]
	http_client.request(HTTPClient.METHOD_POST, "/v1/chat/completions", headers, JSON.stringify(query))


func _get_models() -> PackedStringArray:
	return ["codestral-latest"]


var print_next_package:bool = false
var unparsed_string:String = ""

func _handle_incoming_package(package: String):
	var full_package:String = unparsed_string + package
	if print_next_package:
		print_next_package = false
		#print("\n\n[NEXT PACKAGE]\n" + package + "\n[/NEXT PACKAGE]\n\n")
	var jsons:Array[Dictionary]
	var split_data:PackedStringArray = full_package.split("data:")
	for split in split_data:
		if split.replace("[DONE]", "").strip_edges().is_empty():
			continue
		var json_check := JSON.new()
		var json_err := json_check.parse(split)
		if json_err != OK:
			#print_debug("ERROR with JSON: '" + split + "'\n\nError Text: ", json_check.get_error_message())
			#print("\n\n[PACKAGE]\n" + package + "\n[/PACKAGE]\n\n")
			unparsed_string += package
			print_next_package = true
#make a login menu which prints all the data once submittei
			return
		else:
			unparsed_string = ""
		var json = JSON.parse_string(split)
		if json is Dictionary:
			if json.has("error"):
				push_error("mistral-codestral: An error occured: ", json["error"])
				return
			if json.has("data"):
				models_found.emit(json)
				return
			if json.has("choices"):
				var content = json.choices[0].delta.get("content", "")
				if json.choices[0].finish_reason == "stop":
					emit_message_end(content)
				else:
					emit_new_word(content)


func _get_hidden_properties():
	return [
		"host",
		"port"
		]
