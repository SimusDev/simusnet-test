extends Control

@onready var address: LineEdit = $VBoxContainer/address
@onready var packets: LineEdit = $VBoxContainer/packets
@onready var packet: LineEdit = $VBoxContainer/packet
@onready var start: Button = $VBoxContainer/HBoxContainer/start
@onready var stop: Button = $VBoxContainer/HBoxContainer/stop
@onready var sent: Label = $VBoxContainer/sent
@onready var attackers: Node = $Attackers
@onready var attackers_count: LineEdit = $VBoxContainer/attackers_count
@onready var title: Label = $title

@export var _attacker_scene: PackedScene

var status: bool = false
var sent_count: int = 0

func _ready() -> void:
	get_tree().root.get_window().size = Vector2i(640, 480)
	
	_update_buttons()

func _physics_process(delta: float) -> void:
	title.text = "DOS ATTACKER (%s FPS)" % Engine.get_frames_per_second()

func set_status(new: bool) -> void:
	if status == new:
		return
	
	status = new
	
	
	_update_attackers()
	_update_buttons()

func _update_buttons() -> void:
	start.disabled = status
	stop.disabled = !status

func _update_attackers() -> void:
	await SD_Nodes.clear_all_children(attackers)
	
	if not status:
		return

	for scene in int(attackers_count.text):
		var splitted: PackedStringArray = address.text.split(":")
		if splitted.size() == 2:
			var attacker: Node = _attacker_scene.instantiate()
			attacker.ip = splitted[0]
			attacker.port = int(splitted[1])
			attacker.packet_count = int(packets.text)
			attacker.packet = packet.text
			attackers.add_child(attacker)

func _on_start_pressed() -> void:
	set_status(true)

func _on_stop_pressed() -> void:
	set_status(false)
