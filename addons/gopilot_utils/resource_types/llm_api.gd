@tool
class_name GopilotApiHandler

## The http client used to perform all the requests
var http_client:HTTPClient

## The chat requester used to emit the new words and the end of the message
var chat_requester:ChatRequester


#region non-overridable methods
## Emits the new word to the [ChatRequester]
func emit_new_word(new_word:String) -> void:
	if !chat_requester:
		push_error("GopilotApiHandler: _chat_requester not set! Please report this error!")
		return
	else:
		message_so_far += new_word
		chat_requester.new_word.emit(new_word)

var message_so_far:String = ""

## Emits the end of the message to the [ChatRequester]
func emit_message_end(last_token:String) -> void:
	message_so_far += last_token
	if !chat_requester:
		push_error("GopilotApiHandler: _chat_requester not set! Please report this error!")
		return
	else:
		chat_requester.new_word.emit(last_token)
		chat_requester.message_end.emit(message_so_far)
		message_so_far = ""
#endregion


#region overridable methods
## Overridable. Sends a conversation request to the API. [param conversation] is structured like this[br][codeblock]
## [
##    {
##        "role": "user",
##        "content": "Hello, how are you?"
##    },
##    {
##        "role": "assistant",
##        "content": "I'm fine, thank you!"
##    }
## ]
## [/codeblock][br]
## If [param] conversation includes a prefix, it will end with a [code]{"role":"assistant", "content":"the prefix is here"}[/code] entry.[br]
# [param streaming] is a boolean that indicates whether the response should be streamed or not.
## [param json_mode] is a boolean that indicates whether the response should be in JSON mode or not.
func _send_conversation_request(conversation:Array[Dictionary], streaming:bool, json_mode:bool) -> void:
	push_error("GopilotApiHandler: '_send_conversation_request' not implemented! Aborting")


## Overridable. Sends a raw completion request to the API. [param prefix] is the prefix to complete.
func _send_raw_completion_request(prefix:String, streaming:bool) -> void:
	push_error("GopilotApiHandler: '_send_raw_completion_request' not implemented! Aborting")


## Overridable. Requests a fill-in-the-middle operation. Used for code-completion
func _send_fill_in_the_middle_request(prefix:String, suffix:String, streaming:bool) -> void:
	push_error("GopilotApiHandler: '_send_fill_in_the_middle_request' not implemented! Aborting")


func _handle_incoming_package(package:String) -> void:
	push_error("GopilotApiHandler: '_handle_incoming_package' not implemented! Aborting")


## Overridable. Asynchronous. Will be awaited to get the models to accomodate for request time.
func _get_models() -> PackedStringArray:
	push_error("GopilotApiHandler: '_get_models_request' not implemented! Aborting")
	return []


## Returns a list of overrides for the properties for the [ChatRequester]. For example, overriding the 'host', 'port' or 'model'
func _get_default_properties() -> Dictionary:
	return {}



## Overridable. Returns a list of hidden properties for the [ChatRequester]. Every property name in the array will be hidden from the user and is not editable in the inspector
func _get_hidden_properties() -> PackedStringArray:
	return []


#endregion
