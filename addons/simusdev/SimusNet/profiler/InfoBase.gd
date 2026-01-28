extends Control

@onready var key_label: Label = $Key
@onready var up_traffic: Button = $HBoxContainer/UpTraffic
@onready var down_traffic: Button = $HBoxContainer/DownTraffic

func _ready() -> void:
	update()

func update() -> void:
	pass
