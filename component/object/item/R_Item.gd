class_name R_Item extends R_WorldObject

@export var use_cooldown:float = 1.0

@export_group("ClientSide Prefabs")
@export var clientside_prefabs: Array[PackedScene] = []

@export_group("Audio")
@export var pickup_sound: Array[AudioStream]
@export var inspect_sound:R_SoundObject
