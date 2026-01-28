class_name MetadataMaterial extends Resource

@export_group("Physics")
@export var resistance:float = 1.0

@export_group("Sound")
@export var impact_sounds:Array[AudioStream]
@export var bullet_impact_sounds:Array[AudioStream]
@export var break_sounds:Array[AudioStream]
@export var footstep_sounds:Array[AudioStream]

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
