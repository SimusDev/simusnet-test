extends R_Entity
class_name R_Player

static var _players: Dictionary[String, R_Player]

static func get_player_list() -> Array[R_Player]:
	return _players.values()

static func find_by_id(value: String) -> R_Player:
	return _players.get(value)

func _registered() -> void:
	super()
	_players[id] = self

func _unregistered() -> void:
	super()
	_players.erase(self)
