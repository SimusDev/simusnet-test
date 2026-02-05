extends Control

@export var character_select_button:PackedScene
@export var location_select_button:PackedScene

@onready var character_portrait: Control = %character_portrait
@onready var location_portrait: Control = %location_portrait

@onready var actions_container: VBoxContainer = %actions_container
@onready var character_list_container: VBoxContainer = %character_list_container
@onready var location_list_container: VBoxContainer = %location_list_container

@onready var spawn_button: Button = %spawn_button

var current_character:R_Player :
	set(val):
		current_character = val
		_character_update()

var current_location:R_LocationPoint :
	set(val):
		current_location = val
		_location_update()

func _ready() -> void:
	if CT_Playable.get_local():
		hide()
	
	EVENT.on_player_spawned_local.listen(_on_player_spawned)
	EVENT.on_player_despawned_local.listen(_on_player_despawned)
	
	_full_update()
	
	spawn_button.pressed.connect(
		func():
			if not current_location:
				return
			
			if not current_character:
				return
			
			CT_CharacterSelect.request_spawn(
				current_location,
				current_character
			)
	)

func _on_player_spawned() -> void:
	hide()

func _on_player_despawned() -> void:
	show()

func _full_update() -> void:
	_update_actions_container()
	_update_character_list_container()
	_update_location_list_container()

func _character_update() -> void:
	character_portrait.get_node(
		"Head/title"
		).set(
			"text",
			current_character.resource_name
			)

func _location_update() -> void:
	location_portrait.get_node(
		"LocationName"
		).set(
			"text",
			current_location.resource_name
			)

func _update_actions_container() -> void:
	pass#_clear_container(actions_container)

func _update_character_list_container() -> void:
	_clear_container(character_list_container)
	
	for player in R_Player.get_player_list():
		_add_character_select_button(player)

func _update_location_list_container() -> void:
	_clear_container(location_list_container)
	
	var locations: Array[R_LocationPoint] = await CT_CharacterSelect.async_get_spawn_locations()
	for location in locations:
		_add_location_select_button(location)

func _clear_container(container_node:Node) -> void:
	SD_Nodes.clear_all_children(container_node)

func _add_character_select_button(resource:R_Player) -> void:
	var new_btn = character_select_button.instantiate()
	
	if new_btn is Button:
		character_list_container.add_child(new_btn)
		
		new_btn.get_node("Icon").set("texture", resource.get_icon())
		new_btn.get_node("CharacterName").set("text", resource.resource_name)
		new_btn.pressed.connect(func():
			current_character = resource
			for btn in character_list_container.get_children():
				btn.set("is_current", false)
			new_btn.set("is_current", true)
			)

func _add_location_select_button(resource:R_LocationPoint) -> void:
	var new_btn = location_select_button.instantiate()
	if new_btn is Button:
		location_list_container.add_child(new_btn)
		
		new_btn.get_node("Icon").set("texture", resource.level.icon)
		new_btn.get_node("LocationName").set("text", resource.name)
		new_btn.pressed.connect(func():
			current_location = resource
			for btn in location_list_container.get_children():
				btn.set("is_current", false)
			new_btn.set("is_current", true)
			)
