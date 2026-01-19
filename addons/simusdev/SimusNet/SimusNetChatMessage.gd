extends Resource
class_name SimusNetChatMessage

var _text: String = ""

var _color: Color = Color.WHITE
var _data: Dictionary = {}

var _peer_id: int = SimusNetConnection.SERVER_ID

func get_peer_id() -> int:
	return _peer_id

func get_data() -> Dictionary:
	return _data

func set_data(new: Dictionary) -> void:
	_data = new

func get_color() -> Color:
	return _color

func set_color(new: Color) -> SimusNetChatMessage:
	_color = new
	return self

func get_text() -> String:
	return _text

func set_text(new: Variant) -> SimusNetChatMessage:
	_text = str(new)
	return self

func _init(text: Variant = "") -> void:
	_text = str(text)

func serialize() -> Dictionary:
	var result: Dictionary = {}
	if !_text.is_empty():
		result[0] = _text
	if _color != Color.WHITE:
		result[1] = _color
	if _peer_id > SimusNetConnection.SERVER_ID:
		result[2] = _peer_id
	
	return result

static func deserialize(data: Dictionary) -> SimusNetChatMessage:
	var message: SimusNetChatMessage = SimusNetChatMessage.new()
	message._text = data.get(0, "")
	message._color = data.get(1, Color.WHITE)
	message._peer_id = data.get(2, SimusNetConnection.SERVER_ID)
	return message
