@icon("res://component/icons/playable.png")
extends Node
class_name CT_Playable

@export var node: Node3D : get = get_playable_node

static var _list: Array[CT_Playable] = []

static var _local: CT_Playable

@export_group("VoiceChat", "voice_chat")
@export var _voice: CT_VoiceChat
@export var voice_chat_output: AudioStreamPlayer3D

var _level: LevelInstance

signal on_voice_chat_status_change(status: bool)

func get_level() -> LevelInstance:
	return _level

func get_playable_node() -> Node3D:
	if is_instance_valid(node):
		return node
	return null

func get_voice_chat_status() -> bool:
	if _voice:
		return !_voice.is_muted()
	return false

func _input(event: InputEvent) -> void:
	if !_voice:
		return
	
	if Input.is_action_just_pressed("voice"):
		_voice.set_muted(false)
		on_voice_chat_status_change.emit(true)
	
	elif Input.is_action_just_released("voice"):
		_voice.set_muted(true)
		on_voice_chat_status_change.emit(false)

static func get_list() -> Array[CT_Playable]:
	return _list

static func get_local() -> CT_Playable:
	if !is_instance_valid(_local):
		_local = null
	return _local

func get_peer_id() -> int:
	return get_multiplayer_authority()

func is_local() -> bool:
	return get_local() == self

func _ready() -> void:
	SimusNetIdentity.register(self)
	
	if voice_chat_output:
		if !is_instance_valid(_voice):
			_voice = CT_VoiceChat.new()
			_voice.name = "voice"
			_voice._output_player = voice_chat_output
			_voice._muted = true
			_voice.set_multiplayer_authority(get_multiplayer_authority())
			add_child(_voice)
	else:
		printerr(get_path(), ": ", "voice chat is not configured.")
	
	SD_ECS.append_to(node, self)
	
	if SimusNet.is_network_authority(self):
		_local = self
		EVENT.on_player_spawned_local.setup(self).publish()
	
	set_process_input(is_local())
	
	EVENT.on_player_spawned.setup(self).publish()

static func find_in(target: Node) -> CT_Playable:
	return SD_ECS.find_first_component_by_script(target, [CT_Playable])

func _enter_tree() -> void:
	if !node:
		node = get_parent()
	
	_level = LevelInstance.find_above(self)
	
	_list.append(self)

func _exit_tree() -> void:
	_list.erase(self)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			EVENT.on_player_despawned.setup(self).publish()
			if self == get_local():
				EVENT.on_player_despawned_local.setup(self).publish()
