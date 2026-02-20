extends EditorInspectorPlugin

#const EMBED_DOCUMENTS_EDITOR:PackedScene = preload("res://addons/gopilot_utils/scenes/embedded_documents_editor.tscn")
#const EMBED_TESTER:PackedScene = preload("res://addons/gopilot_utils/scenes/embed_tester.tscn")
var read_models_btn := Button.new()


func _init() -> void:
	read_models_btn.text = "Read models"


func _can_handle(object: Object) -> bool:
	return object is EmbedRequester

# Parse Property
func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	#if name == "import_embeddings_button":
		#var embed_documents_editor:ConfirmationDialog = EMBED_DOCUMENTS_EDITOR.instantiate()
		#var btn:= Button.new()
		#btn.text = "Import Embeddings"
		#btn.name = "Import"
		#btn.add_child(embed_documents_editor)
		#embed_documents_editor.set_requester(object)
		#embed_documents_editor.set_embeddings(object.embeddings)
		#btn.pressed.connect(func():
			#embed_documents_editor.set_requester(object)
			#embed_documents_editor.set_embeddings(object.embeddings)
			#embed_documents_editor.popup())
		#embed_documents_editor.hide()
		#add_custom_control(btn)
		#return true
	#if name == "test_button" and object.embeddings != []:
		#var tester := EMBED_TESTER.instantiate()
		#var btn:= Button.new()
		#tester.hide()
		#btn.add_child(tester)
		#tester.set_requester(object)
		#btn.text = "Test it out"
		#btn.name = "Test"
		#btn.pressed.connect(func():
			#tester.popup())
		#add_custom_control(btn)
		#return true
	#if name == "model":
		#if object.model == "":
			#var dup := read_models_btn.duplicate()
			#
			#add_custom_control(dup)
			#pass
		#return true
	return false

# Read Models Button
var model_reader := HTTPClient.new()

# Read Models Function
func _read_models() -> PackedStringArray:
	var models:PackedStringArray = []
	return models
