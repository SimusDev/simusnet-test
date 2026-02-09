extends CT_AnimationEvents
class_name CT_AnimationEventsCharacter

static func async_find_above(from: Node, attempts: int = 1) -> CT_AnimationEventsCharacter:
	return await _async_find_above_internal(from, 0, attempts, CT_AnimationEventsCharacter)
