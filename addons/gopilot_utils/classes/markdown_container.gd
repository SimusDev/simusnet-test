@tool
extends VBoxContainer
class_name MarkdownContainer


@export_multiline var text:String = "":
	set(new):
		text = new
		_set_text(new)

## [CodeEdit] to duplicate for each code block
@export var code_edit:CodeEdit

## [RichTextLabel] to duplicate for each text block (markdown converted to BBCode)
@export var richtext_label:RichTextLabel


## Internal variable! Contains all the converted text, seperated by converted bbcode and code blocks in this format[br]
## [codeblock]
## [
##    {
##        "type": "bbcode",
##        "content": "Some bbcode here!\nLook, [b]this text is bold![/b]"
##    },
##    {
##        "type": "code",
##        "content": "Some code here!\nLook, this text is code!"
##    }
## ]
## [/codeblock]
##
## This is used to display the text in the editor, so it can be edited properly
var text_segments:Array[Dictionary] = [
	
]

const markdown_code_begin:String = "(^|\\n)```([\\S]*)$"
var markdown_code_begin_regex:RegEx = RegEx.create_from_string(markdown_code_begin)
const markdonwn_code_end_regex:String = "(^|\\n)```($|\\n)"
var markdown_code_end_regex:RegEx = RegEx.create_from_string(markdonwn_code_end_regex)
#const markdown_code_separator_expression:String = r"```(?:[\s\S]*?)\n(?<code>[\s\S]*?)(?:\n```|$|\n)|(?<text>[^`]+|[^`]*`)"
const markdown_code_separator_expression:String = r"```(?<language>[\s\S]*?)\n(?<code>[\s\S]+?)(?:[\s]+```|$)|(?<markdown>(?!\n)(?:(?!```[\s\S]*?(?:[\s\S]))[\s\S])+)"


#const markdown_code_separator_expression:String = r"```[\s\S]*?\n(?<code>[\s\S]+?)```|(<text>(?:(?!```)[\s\S])+)"
var markdown_code_block_separator:RegEx = RegEx.create_from_string(markdown_code_separator_expression)

func _set_text(new_text:String):
	var new_segments:Array[Dictionary] = _markdown_to_segments(new_text)
	
	# Inserting the segments into text controls
	_construct_elements(new_segments, text_segments)
	for segment in new_segments.size():
		get_child(segment).text = new_segments[segment]["content"]
	
	text_segments = new_segments
	




## Constructs the nodes for containing both bbcode and code[br]
## Does not assign text
func _construct_elements(new_segments:Array[Dictionary], old_segments:Array[Dictionary]):
	var new_amount:int = new_segments.size()
	var old_amount:int = old_segments.size()
	
	#for i in get_children():
		#i.queue_free()
	
	if old_amount == 0 or new_amount == 0:
		_full_reconstruct(new_segments)
		return
	# If first type changes (usually from markdown to code block)
	if new_segments[0]["type"] != old_segments[0]["type"]:
		# Freeing all children to make space for new text controls
		for child in get_children():
			child.queue_free()
		
		# Fully reconstructing the text controls
		_full_reconstruct(new_segments)
		return
	
	if new_amount > old_amount:
		for element:int in new_amount - old_amount:
			# Adding new text control
			if new_segments[element-1]["type"] == "bbcode":
				var bbcode_text := richtext_label.duplicate()
				bbcode_text.show()
				add_child(bbcode_text)
			
			elif new_segments[element-1]["type"] == "code":
				var code_text := code_edit.duplicate()
				code_text.show()
				add_child(code_text)
		return
	elif new_amount == old_amount:
		# If the amount of text controls is the same, we can just update the text
		for element:int in new_amount:
			if new_segments[element]["type"] != old_segments[element]["type"]:
				# If the type of the text control changes, we need to reconstruct the text controls
				_full_reconstruct(new_segments)
				return
			else:
				# If the type of the text control is the same, we can just update the text
				get_child(element).text = new_segments[element]["content"]
				return
	else:
		# If the amount of text controls is less than the old amount, we need to free the extra text controls
		_full_reconstruct(new_segments)


## Converts markdown to segments[br]
## Use [method _construct_elements] instead whenever possible
func _full_reconstruct(segments:Array[Dictionary]):
	for segment in segments:
		if segment["type"] == "bbcode":
			var bbcode_text := richtext_label.duplicate()
			#bbcode_text.text = markdown_to_bbcode(segment["content"])
			bbcode_text.show()
			add_child(bbcode_text)
		elif segment["type"] == "code":
			var code_text := code_edit.duplicate()
			#code_text.text = segment["content"]
			code_text.show()
			add_child(code_text)
		else:
			printerr("Unknown segment type: ", segment["type"])


func _ready() -> void:
	if code_edit is CodeEdit and Engine.is_editor_hint():
		code_edit.syntax_highlighter = GDScriptSyntaxHighlighter.new()
	_compile_regex()


func _markdown_to_segments(markdown:String) -> Array[Dictionary]:
	var segments:Array[Dictionary] = []
	var results := markdown_code_block_separator.search_all(markdown)
	for result in results:
		var code:String = result.get_string("code")
		var text:String = result.get_string("markdown")
		if !code.is_empty():
			if segments.size() != 0 and segments[-1]["type"] == "code":
				segments[-1]["content"] += "\n" + code
			else:
				segments.append(
					{
						"type": "code",
						"content": code
					}
				)
		elif !text.is_empty():
			if segments.size() != 0 and segments[-1]["type"] == "bbcode":
				segments[-1]["content"] += text
			else:
				segments.append(
					{
						"type": "bbcode",
						"content": markdown_to_bbcode(text)
					}
				)
	return segments


func append_markdown_text(markdown:String):
	if markdown == "":
		return
	if text_segments.size() == 0:
		text_segments.append(
			{
				"type": "bbcode",
				"content": ""
			}
		)
	
	#match text_segments[-1]["type"]:
		#"bbcode":
			#
			#pass
		#"code":
			#
			#pass
		#_:
			#printerr("UNHANDLED TEXT TYPE '" + text_segments[-1]["type"] + "'")


var compiled_patterns:Dictionary[RegEx, String] = {}


func _compile_regex():
	for pattern:String in patterns:
		var regex := RegEx.new()
		regex.compile(pattern)
		compiled_patterns[regex] = patterns[pattern]


func markdown_to_bbcode(markdown:String) -> String:
	var result:String = markdown
	for pattern in compiled_patterns:
		var replacement:String = compiled_patterns[pattern]
		result = pattern.sub(result, replacement, true)
	return result



var patterns:Dictionary[String, String] = {
	# Inline code
	"`([^`]*?)(`|$)": "[code][bgcolor=#30303080][color=white]$1[/color][/bgcolor][/code]",

	# Headers (must be at start of line)
	"(?m)^######\\s*(.+?)$": "[font_size=14][b]$1[/b][/font_size]",
	"(?m)^#####\\s*(.+?)$": "[font_size=18][b]$1[/b][/font_size]",
	"(?m)^####\\s*(.+?)$": "[font_size=22][b]$1[/b][/font_size]",
	"(?m)^###\\s*(.+?)$": "[font_size=26][b]$1[/b][/font_size]",
	"(?m)^##\\s*(.+?)$": "[font_size=30][b]$1[/b][/font_size]",
	"(?m)^#\\s*(.+?)$": "[font_size=34][b]$1[/b][/font_size]",

	# Bold and italic (descending priority)
	"\\*\\*\\*([^\\*^\\n]+?|$)(?:\\*\\*\\*|$)": "[b][i]$1[/i][/b]",
	"\\*\\*([^\\*^\\n]+?|$)(?:\\*\\*|$)": "[b]$1[/b]",
	"\\*([^\\*^\\n]+?|$)(?:\\*|$)": "[i]$1[/i]",

	# Link replacement
	"\\[([^\\]]+?)\\]\\(([^\\)]+?)\\)": "[url=$2]$1[/url]"
}
