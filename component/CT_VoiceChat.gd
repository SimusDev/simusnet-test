extends SimusNetVoiceChat
class_name CT_VoiceChat

const MAX_DISTANCE: float = 25.0

var _level: LevelInstance

func _ready() -> void:
	_level = LevelInstance.find_above(self)
	super()
	

func is_visible_for_peer(peer: int) -> bool:
	var local: CT_Playable = CT_Playable.get_local()
	var p: CT_Playable = _level.get_player_by_peer_id(peer)
	if !p or !local:
		return false
	
	var node: Node3D = p.get_playable_node()
	var can: bool = node.global_position.distance_to(local.get_playable_node().global_position) <= MAX_DISTANCE
	print(can)
	return can 
