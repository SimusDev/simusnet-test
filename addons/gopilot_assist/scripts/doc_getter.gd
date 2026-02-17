extends Node

const CLASS_FOLDER := "res://addons/gopilot_assist/class_reference/"

var getter := HTTPClient.new()

@export var host:String


func _ready() -> void:
	getter.connect_to_host(host)


func get_description(_class:String):
	var small_class = _class.to_lower()
	var file:FileAccess
	var file_path:String
	if FileAccess.file_exists(CLASS_FOLDER + "class_" + small_class + ".rst"):
		file = FileAccess.open(CLASS_FOLDER + "class_" + small_class + ".rst", FileAccess.READ)
		var content := file.get_as_text()
		#content = content.split("")
