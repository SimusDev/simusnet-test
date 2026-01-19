extends Control

@export var _characters: GridContainer
@export var _locations: VBoxContainer

@export var _screens: Array[Control] = []
@export var _screens_title: Array[String] = []

@export var _character_button_group: ButtonGroup
@export var _location_button_group: ButtonGroup

var _current_screen: int = 0

func _ready() -> void:
	if CT_Playable.get_local():
		hide()
	
	EVENT.on_player_spawned_local.listen(_on_player_spawned)
	EVENT.on_player_despawned_local.listen(_on_player_despawned)
	
	for player in R_Player.get_player_list():
		var ui: Button = load("uid://ccrgm8otgtdcq").instantiate()
		ui.resource = player
		_characters.add_child(ui)
	
	switch_screen(0)
	
	var locations: Array[R_LocationPoint] = await CT_CharacterSelect.async_get_spawn_locations()
	for location in locations:
		var ui: Button = load("uid://b3bi3s47bjcjo").instantiate()
		ui.resource = location
		_locations.add_child(ui)


func switch_screen(id: int) -> void:
	if id > _screens.size() - 1:
		id = 0
	if id < 0:
		id = _screens.size() - 1
	
	for i in _screens:
		i.visible = _screens.find(i) == id
	
	$%Title.text = _screens_title[id]
	
	_current_screen = id

func _on_player_spawned() -> void:
	hide()

func _on_player_despawned() -> void:
	show()

func _on_back_pressed() -> void:
	switch_screen(_current_screen - 1)

func _on_next_pressed() -> void:
	switch_screen(_current_screen + 1)

func _on_done_pressed() -> void:
	var button_character: Button = _character_button_group.get_pressed_button()
	var button_location: Button = _location_button_group.get_pressed_button()
	if button_character and button_location:
		CT_CharacterSelect.request_spawn(button_location.resource, button_character.resource)
