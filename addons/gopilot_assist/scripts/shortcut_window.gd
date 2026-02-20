@tool
extends AcceptDialog

func _ready() -> void:
	#set_process_input(false)
	%PrimaryShortcutBtn.pressed.connect(_on_shortcut_button_pressed.bind(%PrimaryShortcutBtn))
	%SecondaryShortcutBtn.pressed.connect(_on_shortcut_button_pressed.bind(%SecondaryShortcutBtn))
	%ChatShortcutBtn.pressed.connect(_on_shortcut_button_pressed.bind(%ChatShortcutBtn))


var current_button:Button

var last_keycode := ""

func _listener_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and !event.is_echo() and event.is_pressed():
		var keycode:String = event.as_text_keycode()
		if "+" not in keycode:
			return
		if keycode in last_keycode:
			return
		last_keycode = keycode
		%ShortcutListener.text = keycode


func _on_shortcut_button_pressed(button:Button) -> void:
	current_button = button
	last_keycode = ""
	%ShortcutListener.text = "Listening..."
	set_process_input(true)
	match button.name:
		"PrimaryShortcutBtn": %InputListenerWindow.title = "Setting primary shortcut..."
		"SecondaryShortcutBtn": %InputListenerWindow.title = "Setting secondary shortcut..."
	%InputListenerWindow.popup()


func _on_popup() -> void:
	%PrimaryShortcutBtn.text = get_parent().settings["primary_shortcut"]
	%SecondaryShortcutBtn.text = get_parent().settings["secondary_shortcut"]


func _on_input_listener_window_confirmed() -> void:
	set_process_input(false)
	if !last_keycode.is_empty():
		match current_button.name:
			"PrimaryShortcutBtn":
				%PrimaryShortcutBtn.text = last_keycode
			"SecondaryShortcutBtn":
				%SecondaryShortcutBtn.text = last_keycode
			"ChatShortcutBtn":
				%ChatShortcutBtn.text = last_keycode
