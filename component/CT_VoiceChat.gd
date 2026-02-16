@tool
class_name CT_VoiceChat extends SimusNetVoiceChat
var _level: LevelInstance

func _ready() -> void:
	super()
	_level = LevelInstance.find_above(self)

func is_visible_for_peer(peer: int) -> bool:
	if get_max_distance() == 0.0:
		return true
	
	var local: CT_Playable = CT_Playable.get_local()
	var p: CT_Playable = _level.get_player_by_peer_id(peer)
	if !p or !local:

		return false
	
	var node: Node3D = p.get_playable_node()
	var can: bool = node.global_position.distance_to(local.get_playable_node().global_position) <= get_max_distance()
	return can 
