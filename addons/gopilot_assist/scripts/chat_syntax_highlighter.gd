extends CodeHighlighter


func _init() -> void:
	#add_keyword_color("/scene", Color.LIGHT_GREEN)
	#add_keyword_color("/script", Color.LIGHT_GREEN)
	add_color_region("/", " ", Color.LIGHT_SKY_BLUE)
	symbol_color = Color.WHITE
	number_color = Color.WHITE
	function_color = Color.WHITE
	member_variable_color = Color.WHITE
