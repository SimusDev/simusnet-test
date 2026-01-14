@static_unload
extends EVENT
class_name EVENT_Player

var playable: CT_Playable

func setup(_playable: CT_Playable) -> EVENT_Player:
	playable = _playable
	return self
