extends Button

@onready var username_line_edit:LineEdit = get_node("../../../Login/UsernameHBox/UsernameLineEdit")
@onready var password_line_edit:LineEdit = get_node("../../../Login/PasswordHBox/PasswordLineEdit")
@onready var remember_me_check_box:CheckBox = get_node("../../../Login/RememberMeHBox/RememberMeCheckBox")

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	var username = username_line_edit.text
	var password = password_line_edit.text
	var remember_me = remember_me_check_box.button_pressed

	# Handle login logic here
	print("Login button pressed with username: ", username, " and remember me: ", remember_me)
