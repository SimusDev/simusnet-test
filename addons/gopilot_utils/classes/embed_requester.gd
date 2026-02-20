@tool
@icon("res://addons/gopilot_utils/textures/embed_requester_icon.svg")
## Allows for embedding multiple files into a database.
## Similar documents can be retrieved using the [color=lightblue]get_closest_embeddings[/color] function
extends Node
class_name EmbedRequester

## Internal constant. Defines type of data being sent via POST request to ollama
const headers = ["Content-Type: application/json"]

@export var model:String = "nomic-embed-text"
##URL to the ollama endpoint. When running ollama on your local machine, keep this as is
@export var host:String = "http://127.0.0.1"
##Port to the ollama connection
@export var port:int = 11434
@export var in_editor:bool = false
@export_group("Data")
@export var embeddings:Array[TextEmbedding]
##Show what exactly how the conversation between you and the assistant goes on in the console
@export_group("Debug")
@export var debug_mode:bool = false

signal embedding_finished(embedding:Array[PackedFloat32Array])
signal segment_finished

var client := HTTPClient.new()
var connected:bool = false



func _ready():
	if Engine.is_editor_hint() and !in_editor:
		return
	var err = client.connect_to_host(host, port)
	assert(err == OK)

func _process(delta):
	if Engine.is_editor_hint() and !in_editor:
		return
	client.poll()
	if(client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING):
		if(!connected):
			if debug_mode:
				print("Connecting...")
	elif(client.get_status() == HTTPClient.STATUS_CONNECTED):
		if(!connected):
			connected = true
			if debug_mode:
				print("EmbedRequester '", name, "' Connected!")
	elif(client.get_status() == HTTPClient.STATUS_DISCONNECTED):
		if(connected):
			connected = false
			if debug_mode:
				print("Disconnected!")
	elif(client.get_status() == HTTPClient.STATUS_BODY):
		if debug_mode:
			print("Requesting...")
		if(client.has_response()):
			var chunk = client.read_response_body_chunk()
			var jsdata = JSON.new()
			jsdata.parse(chunk.get_string_from_utf8())
			var data = jsdata.get_data()
			if(data != null):
				var word:String
				if data.has("error"):
					push_error("EmbedRequester Error: ", data["error"])
					return
				if debug_mode:
					print("Response: ", data)
				#print("embeddings: ", data["embeddings"])
				#print("full data: ", data)
				embedding_finished.emit(data["embeddings"])


## Returns the semantic distance between two [TextEmbedding]s[br]
## Relies on [method get_similar_to]
func get_distance_between_embedding_data(data_1:PackedFloat32Array, data_2:PackedFloat32Array) -> float:
	var distance := 0.0
	if len(data_1) != len(data_2):
		push_error("EmbedRequester error: Embeddings data doesn't have the same length! Not comparable!")
		return 0.0
	for i in data_1.size():
		distance += abs(data_1[i] - data_2[i])
	return distance


## Compares given [param text] to an array of [param _embeds]. Compares to saved embeddings in [member embeddings] by default
func get_similar_to(text:String, _embeds:Array[TextEmbedding] = embeddings) -> Array[TextEmbedding]:
	var text_embed := (await get_embedding_for(text))
	var embeddings_data:Array[PackedFloat32Array] = []
	for embed in _embeds:
		embed.distance = get_distance_between_embedding_data(embed.data, text_embed)
	var custom_sort:Callable = func(first:TextEmbedding, second:TextEmbedding) -> bool:
		if first.distance < second.distance:
			return true
		return false
	var sorted_embeds:Array[TextEmbedding] = _embeds.duplicate()
	sorted_embeds.sort_custom(custom_sort)
	return sorted_embeds

## Embeds multiple text chunks at once into [member embeddings]
func embed_multiple(texts:PackedStringArray):
	var embeds := await get_embeddings_for(texts)
	for i in embeds.size():
		var new_res := TextEmbedding.new()
		new_res.text = texts[i]
		new_res.data = embeds[i]
		embeddings.append(new_res)


## Embeds a text into [member embeddings]
func embed_text(text:String):
	client.poll()
	var status := client.get_status()
	if status != client.Status.STATUS_CONNECTED:
		push_error("Error: Current state != CONNECTED but is ", status)
	if debug_mode:
		print("Embeds text...")
	var data := await get_embedding_for(text)
	print("\tRetrieved embedding from ollama...")
	var embedding := TextEmbedding.new()
	embedding.text = text
	embedding.data = data
	embeddings.append(embedding)
	if debug_mode:
		print("\tDone! Added text to '", name, "' (EmbedRequester)")


##Removes all file data, including their content, file path and their embeddings.
func clear_embeddings():
	embeddings = []


##Returns an embedding for a given String. Does not handle chunking and overlap
func get_embedding_for(text:String) -> PackedFloat32Array:
	client.poll()
	if client.get_status() != client.Status.STATUS_CONNECTED:
		await get_tree().create_timer(0.05).timeout
		if client.get_status() != client.Status.STATUS_CONNECTED:
			push_error("Not connected but ", client.get_status())
	client.request(HTTPClient.METHOD_POST, host + ":" + str(port) + "/api/embed", [], JSON.stringify({"model":model, "input":text}))
	var result:PackedFloat32Array = (await embedding_finished)[0]
	return result


##Returns an Array of embeddings for a given Array of Strings. Can be faster than requesting individually
func get_embeddings_for(messages:PackedStringArray) -> Array[PackedFloat32Array]:
	client.request(HTTPClient.METHOD_POST, host + ":" + str(port) + "/api/embed", [], JSON.stringify({"model":model, "input":messages}))
	var result:Array[PackedFloat32Array] = []
	for i in await embedding_finished:
		result.append(PackedFloat32Array(i))
	await get_tree().create_timer(0.05)
	return result
