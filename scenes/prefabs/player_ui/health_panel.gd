extends Panel

@onready var health_label: SD_RichTextLabelSimple = $HealthLabel
var entity:Entity
var health:CT_Health

const TEXT_BBCODE = "[color=#db9702]HEALTH [font_size=46]%s"

func _ready() -> void:
	if is_instance_valid(health):
		print("SEex")
		health.on_value_changed.connect(_update)
		health.on_value_max_changed.connect(_update)
		_update()
	print("SEex = EWX")

func _update() -> void:
	if is_instance_valid(health):
		health_label.text = str(
			TEXT_BBCODE % snappedf(health.value, .1)
			)
