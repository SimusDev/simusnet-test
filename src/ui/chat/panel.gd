extends Panel

@export var message_scene: PackedScene
@export var container: Control
@export var chat: SimusNetChat

@export var line_edit: LineEdit

func _ready() -> void:
	chat.on_message_received.connect(_on_message_received)

func _on_message_received(msg: SimusNetChatMessage) -> void:
	var ui: Control = message_scene.instantiate()
	ui.message = msg
	container.add_child(ui)

func _on_line_edit_text_submitted(new_text: String) -> void:
	chat.request(SimusNetChatMessage.new(new_text))
	line_edit.text = ""

func _on_sd_ui_interface_menu_opened() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	line_edit.grab_focus()
