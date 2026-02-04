class_name MetadataMaterial extends Resource

@export_group("Physics")
@export var resistance:float = 1.0

@export_group("VFX")
@export var bullet_impact_particles:PackedScene = preload("res://src/prefabs/bullet_impact_vfx.tscn")
@export_subgroup("Decal")
@export var bullet_impact_decal:PackedScene = preload("res://src/prefabs/bullet_decal.tscn")
@export var melee_impact_decal:PackedScene = preload("res://src/prefabs/bullet_decal.tscn")

@export_group("Sound")
@export var impact_sounds:Array[AudioStream] = [
	preload("res://audio/hl2/physics/surfaces/sand_impact_bullet1.wav"),
	preload("res://audio/hl2/physics/surfaces/sand_impact_bullet2.wav"),
	preload("res://audio/hl2/physics/surfaces/sand_impact_bullet3.wav"),
	preload("res://audio/hl2/physics/surfaces/sand_impact_bullet4.wav"),
]

@export var bullet_impact_sounds:Array[AudioStream] = [
	preload("res://audio/hl2/physics/surfaces/sand_impact_bullet1.wav"),
	preload("res://audio/hl2/physics/surfaces/sand_impact_bullet2.wav"),
	preload("res://audio/hl2/physics/surfaces/sand_impact_bullet3.wav"),
	preload("res://audio/hl2/physics/surfaces/sand_impact_bullet4.wav"),
]

@export var break_sounds:Array[AudioStream] =  [
	
]

@export var footstep_sounds:Array[AudioStream] = [
	preload("res://audio/hl2/player/footsteps/grass1.wav"),
	preload("res://audio/hl2/player/footsteps/grass2.wav"),
	preload("res://audio/hl2/player/footsteps/grass3.wav"),
	preload("res://audio/hl2/player/footsteps/grass4.wav"),
	]


static func find_in(node:Node, find_in_parents:bool = true) -> MetadataMaterial:
	if node.has_meta("MetadataMaterial"):
		return node.get_meta("MetadataMaterial")
	elif find_in_parents:
		var found:MetadataMaterial = null
		var parents:Array[Node] = []
		var current_parent = node.get_parent()
		
		while current_parent != null:
			if current_parent.has_meta("MetadataMaterial"):
				var meta = current_parent.get_meta("MetadataMaterial")
				if meta is MetadataMaterial:
					found = meta
			parents.append(current_parent)
			current_parent = current_parent.get_parent()
		return found
	return null

static func safe_find_in(node:Node, find_in_parents:bool = true) -> MetadataMaterial:
	var found:MetadataMaterial = find_in(node, find_in_parents)
	if not found:
		return MetadataMaterial.new()
	return found
