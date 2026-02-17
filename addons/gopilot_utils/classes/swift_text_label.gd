@tool
extends RichTextLabel
class_name SwiftTextLabel

@export var smoothing:bool = true

@export var fill_duration:float = 1.0

@export var use_markdown:bool = false

@onready var last_character_amount:int = text.length()


var length_tweener:Tween


func _set(property: StringName, value: Variant) -> bool:
	if property == "text":
		if use_markdown:
			print("before conversion: ", value)
			value = markdown_to_bbcode(value)
			print("after conversion: ", value)
		if !smoothing or value.length() <= text.length():
			if length_tweener and length_tweener.is_running():
				length_tweener.kill()
			visible_characters = value.length()
			return false
		text = value
		if length_tweener and length_tweener.is_running():
			length_tweener.kill()
		length_tweener = create_tween()
		length_tweener.tween_property(self, "visible_characters", value.length(), fill_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return false





var patterns := {
	# Inline code
	"`([^`]*?)(`|$)": "[code][bgcolor=#30303080][color=white]$1[/color][/bgcolor][/code]",
	
	# Headers (must be at start of line)
	"(?m)^###\\s*(.+?)$": "[font_size=30][b]$1[/b][/font_size]\n",
	"(?m)^##\\s*(.+?)$": "[font_size=35][b]$1[/b][/font_size]\n",
	"(?m)^#\\s*(.+?)$": "[font_size=40][b]$1[/b][/font_size]\n",
	
	# Bold and italic (descending priority)
	"\\*\\*\\*([^\\*]*?)(?:\\*\\*\\*|$)": "[b][i]$1[/i][/b]",
	"\\*\\*([^\\*]*?)(?:\\*\\*|$)": "[b]$1[/b]",
	"\\*([^\\*]*?)(?:\\*|$)": "[i]$1[/i]",
	
	# Link replacement
	"\\[([^\\]]+?)\\]\\(([^\\)]+?)\\)": "[url=$2]$1[/url]"
}
func markdown_to_bbcode(markdown:String) -> String:
	var split := markdown.split("\n```")
	
	var start_with_code:bool = split[0].begins_with("```") or split[0].begins_with("\n```")
	
	var markdown_texts:PackedStringArray
	var code_blocks:PackedStringArray
	
	if start_with_code:
		for i in split.size():
			if i % 2 == 0.0:
				code_blocks.append(split[i])
			else:
				markdown_texts.append(split[i])
	else:
		for i in split.size():
			if i % 2 == 0.0:
				markdown_texts.append(split[i])
			else:
				code_blocks.append(split[i])
	
	var code_regex := RegEx.new()
	code_regex.compile("\\A.*?\\n([\\s\\S]+)\\Z")
	
	for code in code_blocks.size():
		#print("replacing ", code_blocks[code] , "\nwith ", code_regex.sub(code_blocks[code], "$1"))
		code_blocks[code] = code_regex.sub(code_blocks[code], "\n$1").trim_prefix("\n").replace("]", "[rb]")
	
	for text in markdown_texts.size():
		#print("iterating over markdown")
		for pattern in patterns:
			var regex := RegEx.new()
			var err := regex.compile(pattern, true)
			if err != OK:
				continue
			var replacement:String = patterns[pattern]
			var result := regex.sub(markdown_texts[text], replacement, true)
			#if markdown_texts[text] != result:
				#print("from: ", markdown_texts[text], "\nto: ", result)
			markdown_texts[text] = result
	
	#print("code:", code_blocks)
	#print("text:", markdown, "\n")
	var result:String
	var mark_i := 0
	var code_i := 0
	if start_with_code:
		for i in markdown_texts.size() + code_blocks.size():
			if i % 2 == 0.0:
				result += "[code][bgcolor=#30303080][color=white]" + code_blocks[code_i] + "[/color][/bgcolor][/code]"
				code_i += 1
			else:
				result += markdown_texts[mark_i]
				mark_i += 1
	else:
		for i in markdown_texts.size() + code_blocks.size():
			if i % 2 == 0.0:
				result += markdown_texts[mark_i]
				mark_i += 1
			else:
				result += "[code][bgcolor=#30303080][color=white]" + code_blocks[code_i] + "[/color][/bgcolor][/code]"
				code_i += 1
	return result
