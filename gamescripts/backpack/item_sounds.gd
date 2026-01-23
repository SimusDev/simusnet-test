extends CT_GameScript

const SOUNDS: Array[AudioStream] = [
	preload("uid://bboc1j8tyr20d"),
	preload("uid://u62gbqjuiowu")
]

func _play_sound(source: AudioStream, root: Node3D) -> void:
	var audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	audio.autoplay = true
	audio.finished.connect(audio.queue_free)
	audio.stream = source
	audio.bus = "Game"
	audio.max_distance = 10
	root.add_child(audio)

func _ready() -> void:
	EVENT.on_inventory_ready.listen(_on_inventory_ready, true)

func _on_inventory_ready(event: EVENT_InventoryReady) -> void:
	event.source.on_item_added.connect(_on_item_added)

func _on_item_added(slot: CT_InventorySlot, item: CT_ItemStack) -> void:
	var root: Node = item.get_inventory().node
	_play_sound(SOUNDS.pick_random(), root)
