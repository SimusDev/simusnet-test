extends GopilotApiHandler

signal models_found(query: Dictionary)


func _get_default_properties() -> Dictionary:
	return {
		"port": 443,
		"host": "https://openrouter.ai",
	}

func _send_conversation_request(conversation: Array[Dictionary], streaming: bool, json_mode: bool) -> void:
	var query := {
		"model": chat_requester.model,
		"messages": conversation,
		"stream": streaming,
	}
	
	# Add temperature and other options
	if chat_requester.temperature != -0.01:
		query["temperature"] = chat_requester.temperature
	for option in chat_requester.options:
		query[option] = chat_requester.options[option]
	
	# JSON mode handling
	if json_mode:
		query["stop"] = ["\n```"]
		if query["messages"][-1]["role"] == "assistant":
			query["messages"][-1]["content"] = "```json\n"
		else:
			query["messages"].append({"role": "assistant", "content": "```json\n"})
	
	# Add headers with API key
	var headers := [
		"Authorization: Bearer %s" % chat_requester.api_key,
		"Content-Type: application/json"
	]
	
	http_client.request(HTTPClient.METHOD_POST, "/api/v1/chat/completions", headers, JSON.stringify(query))

func _send_fill_in_the_middle_request(prefix: String, suffix: String, streaming: bool) -> void:
	var query := {
		"model": chat_requester.model,
		"prefix": prefix,
		"suffix": suffix,
		"stream": streaming,
	}
	
	# Add temperature and other options
	if chat_requester.temperature != -0.01:
		query["temperature"] = chat_requester.temperature
	for option in chat_requester.options:
		query[option] = chat_requester.options[option]
	
	var headers := [
		"Authorization: Bearer %s" % chat_requester.api_key,
		"Content-Type: application/json"
	]
	
	http_client.request(HTTPClient.METHOD_POST, "/api/v1/completions", headers, JSON.stringify(query))


func _send_raw_completion_request(prompt:String, stream:bool):
	
	pass


func _get_models() -> PackedStringArray:
	
	return []

var print_next_package:bool = false
var unparsed_string:String = ""

func _handle_incoming_package(package: String):
	var full_package:String = unparsed_string + package
	if print_next_package:
		print_next_package = false
	var jsons:Array[Dictionary]
	var split_data:PackedStringArray = full_package.split("data:")
	for split in split_data:
		if split.replace("[DONE]", "").strip_edges().is_empty() or ": OPENROUTER PROCESSING" in split:
			continue
		var json_check := JSON.new()
		var json_err := json_check.parse(split)
		if json_err != OK:
			unparsed_string += package
			print_next_package = true
#make a login menu which prints all the data once submittei
			return
		else:
			unparsed_string = ""
		var json = JSON.parse_string(split)
		if json is Dictionary:
			if json.has("error"):
				push_error("openrouter: An error occured: ", json["error"])
				return
			if json.has("data"):
				models_found.emit(json)
				return
			if json.has("choices"):
				var content = json.choices[0].delta.get("content", "")
				if content.is_empty():
					continue
				if json.choices[0].finish_reason == "stop":
					emit_message_end(content)
				else:
					emit_new_word(content)


func _get_hidden_properties():
	return [
		"host",
		"port"
		]
