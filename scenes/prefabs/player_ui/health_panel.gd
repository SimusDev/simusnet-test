extends Panel

@onready var health_label: SD_RichTextLabelSimple = $HealthLabel
var player:Player
var health:CT_Health

const TEXT_BBCODE = "[color=#db9702]HEALTH [font_size=46]%s"

func _ready() -> void:
	player = Player.get_local()
	if is_instance_valid(player):
		health = SD_ECS.find_first_component_by_script(player, [CT_Health])
	if is_instance_valid(health):
		health.on_value_changed.connect(_update)
		health.on_value_max_changed.connect(_update)
		_update()

func _update() -> void:
	if is_instance_valid(health):
		health_label.text = str(
			TEXT_BBCODE % snappedf(health.value, .1)
			)
