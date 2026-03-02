class_name CT_Radio extends Node

@export var root: Node3D
@export_dir var directory: String
@export_group("Custom References")
@export var audio_player: AudioStreamPlayer3D

var playlist:Array[AudioStream]
var current_idx:int = 0

static func find_above(node: Node) -> CT_Radio:
	for c in node.get_children():
		if c is CT_Radio:
			return c
	
	for c in node.get_children():
		var found = find_above(c)
		if found:
			return found
	
	return null

func _ready() -> void:
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		root.add_child(audio_player)
	
	_scan_audio()

func _scan_audio() -> void:
	for file_path in SD_FileSystem.get_all_files_with_extension_from_directory(directory, SD_FileExtensions.EC_AUDIO):
		var audio = load(file_path)
		if audio is AudioStream:
			playlist.append(audio)
