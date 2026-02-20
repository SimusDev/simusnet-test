extends Button

@onready var tab_container:TabContainer = get_node("../../../..")

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	tab_container.current_tab = 1
