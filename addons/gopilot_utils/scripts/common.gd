extends Control


static func trim_code_block(text:String, convert_to_tabs:bool = true) -> String:
	text = text.trim_prefix("```")
	text = text.trim_prefix("gdscript")
	text = text.trim_prefix("\n")
	text = text.trim_suffix("\n")
	text = text.trim_suffix("\n```")
	if convert_to_tabs:
		text = text.replace("    ", "\t")
	return text


static func fix_broken_json(broken_json: String) -> String:
	var stack = []
	var in_string = false
	var escape_next = false
	var current_key = ""
	var expecting_colon = false
	var expecting_value = false
	
	# First pass: validate and track structure
	for i in range(broken_json.length()):
		var char = broken_json[i]
		
		# Handle escape sequences
		if escape_next:
			escape_next = false
			continue
			
		if char == "\\":
			escape_next = true
			continue
			
		# Handle strings
		if char == "\"" and not escape_next:
			in_string = !in_string
			continue
			
		if in_string:
			continue
			
		# Handle structure
		match char:
			"{":
				stack.push_back("{")
			"[":
				stack.push_back("[")
			"}":
				if stack.size() > 0 and stack.back() == "{":
					stack.pop_back()
			"]":
				if stack.size() > 0 and stack.back() == "[":
					stack.pop_back()
	
	# If we're still in a string, the JSON is broken
	if in_string:
		# Close the string
		broken_json += "\""
	
	# Close remaining open structures
	while stack.size() > 0:
		var last = stack.pop_back()
		if last == "{":
			broken_json += "}"
		elif last == "[":
			broken_json += "]"
	
	# Validate the result
	var json = JSON.new()
	var error = json.parse(broken_json)
	
	# If parsing failed, return empty object
	if error != OK:
		return "{}"
	
	return broken_json



const INCLUDE_PROPERTIES := false
const INCLUDE_CHILDREN := true
const MAX_DEPTH = 5


static func get_node_as_dict(node:Node, depth:int = 0, max_depth:int = MAX_DEPTH, include_properties:bool = INCLUDE_PROPERTIES, include_children := INCLUDE_CHILDREN) -> Dictionary:
	var dict := {}
	if !node.name.begins_with(node.get_class()):
		var n:String = String(node.name)
		if node.unique_name_in_owner:
			n = "%" + n
		dict["name"] = n
	dict["type"] = node.get_class()
	if include_properties:
		var properties:Array[Dictionary] = []
		var prop_list := node.get_property_list()
		for prop in prop_list:
			var n:String = prop["name"]
			if node.property_get_revert(n) != node.get(n):
				properties.append({"name":n, "value":node.get(n)})
		dict["properties"] = properties
	if !node.scene_file_path.is_empty() and depth != 0:
		dict["scene_path"] = node.scene_file_path
	elif depth <= max_depth and node.get_child_count() != 0 and include_children:
		var children:Array[Dictionary] = []
		for child in node.get_children():
			var child_dict := get_node_as_dict(child, depth + 1)
			children.append(child_dict)
		dict["children"] = children
	return dict


static func _node_as_text(node:Node) -> String:
	var text:String = "\"" + node.name + "\""
	if node.get_class() != node.name:
		text += " (" + node.get_class() + ")"
	return str(text)



static func get_node_as_string(node: Node, max_depth: int = MAX_DEPTH, indent: String = "  ", element_prefix: String = "- ", depth: int = 0, node_to_string_method: Callable = _node_as_text) -> String:
	var result = ""
	var prefix = indent.repeat(depth)
	if !node:
		return ""

	# Use the provided node_to_string_method to get the string representation of the node
	result += prefix + element_prefix + node_to_string_method.call(node)
	if depth == 0:
		result += " (root of the scene)"
	result += "\n"

	if depth < max_depth and node.get_child_count() != 0:
		for child in node.get_children():
			result += get_node_as_string(child, max_depth, indent, element_prefix, depth + 1, node_to_string_method)

	return result


const ACTION_KEYS:PackedStringArray = ["get_selected_nodes", "get_selected_code"]

const ACTION_TYPES:PackedStringArray = ["edit_script", "create_script", "edit_scene_tree"]

const ACTION_DESCRIPTION := {
	"get_selected_code":"Gets you the code I have selected in the script editor",
	"get_selected_node":"Gets you the nodes I have selected in the SceneTree",
	"edit_node_property":"Lets you edit a property of a specific node",
}

var overlay:Control

var json_chatter:ChatRequester

var ACTION_SELECTION_PROMPT := """You are an integrated AI assistant in the Godot 4 Game Engine.
Instruction: {.instruction}

What info do you want to get?
You must respond in JSON using this schema
```json
{
	"action":"your_action_here" // Must be one of these: """ + str(ACTION_KEYS) + """
}
```
DO NOT ADD ANY OTHER KEYS!
Only perform an action when the user asks you to do it! If no action is requested, set the action to "reply"."""

const GET_INFO_PROMPT := """You are an integrated AI assistant in the Godot 4 Game Engine.
Instruction: {.instruction}

Would you like to get additional information or respond to me?
You must respond in JSON using this schema
```json
{
	"action":"your_action_here" // Must be either "respond" or "get_info"
}
```
DO NOT ADD ANY OTHER KEYS!
"""


const ANALYSIS_PRT := """Have a look at this conversation:\n{.conversation}\n
What is the intent of the user? What do they want to do?
Think about if the user wants to do something themselves or if they want the AI to do it."""

const ANALYSIS_JSON_PRT := """Provide your findings in JSON using this schema:
```json
{
	"user_intent":"The intent of the user",
	"message_type":type of the message // Should be either "question" or "work_assignment"
}
```
Respond with nothing else."""


## Returns array where first index is the value, and second index is an empty string if there is no error
func parse_value(string: String) -> Array[Variant]:
	print("received this string: ", string)
	var value: Variant
	var load_regex := RegEx.create_from_string(r"^load\((?<path>.+)\)$")
	var load_match := load_regex.search(string)
	if load_match:
		var path = load_match.get_string("path")
		if !FileAccess.file_exists(path):
			return [null, "File not found"]
		value = load(path)
		return [value, ""]

	if string.begins_with("\"") and string.ends_with("\""):
		print("returning string: ", string.trim_prefix("\"").trim_suffix("\""))
		return [string.trim_prefix("\"").trim_suffix("\""), ""]

	if string.count(".") > 0 and string.split(".")[0] in ClassDB.get_class_list():
		var node_constant_regex := RegEx.create_from_string(r"^.+\.(?<constant>[A-Z_]+)$")
		var node_constant_match := node_constant_regex.search(string)
		var _class_name = string.split(".")[0]
		if node_constant_match:
			var constant = node_constant_match.get_string("constant")
			if constant in ClassDB.class_get_integer_constant_list(_class_name):
				value = ClassDB.class_get_integer_constant(_class_name, constant)
				return [value, ""]

	# If all else fails, an expression is used
	var expr := Expression.new()
	var error := expr.parse(string)
	if error != OK:
		return [null, "Error parsing expression: " + expr.get_error_text()]
	var result = expr.execute([], Node.new(), false, false)
	if !expr.get_error_text().is_empty():
		return [null, "Error executing expression: " + expr.get_error_text()]
	value = result
	return [value, ""]


func xml_to_json(xml_string: String) -> String:
	var parser = XMLParser.new()
	var buffer = xml_string.to_utf8_buffer()
	var error = parser.open_buffer(buffer)
	if error != OK:
		print("Error opening XML buffer:", error)
		return ""

	var root = null
	var stack = []
	var current_element = null

	while true:
		error = parser.read()
		if error == ERR_FILE_EOF:
			break
		if error != OK:
			print("Error reading XML:", error)
			break

		var node_type = parser.get_node_type()

		if node_type == XMLParser.NODE_ELEMENT:
			var node_name = parser.get_node_name()
			var attributes_count = parser.get_attribute_count()
			var attributes_dict = {}

			for i in range(attributes_count):
				var attr_name = parser.get_attribute_name(i)
				var attr_value = parser.get_attribute_value(i)
				var parsed_value = parse_value(attr_value)
				attributes_dict[attr_name] = parsed_value

			var element_type = "unknown"
			if attributes_dict.has("class"):
				element_type = attributes_dict["class"]
				attributes_dict.erase("class")
			if attributes_dict.has("type"):
				attributes_dict.erase("type")

			var new_element = { "type": element_type }
			#for key, value in attributes_dict:
				#new_element[key] = value
			for i in attributes_dict.keys():
				var key = i
				var value = attributes_dict[key]
				new_element[key] = value
			if stack.empty():
				root = new_element
			else:
				if not stack[-1].has("children"):
					stack[-1]["children"] = []
				stack[-1]["children"].append(new_element)
			stack.append(new_element)
		elif node_type == XMLParser.NODE_TEXT:
			var text = parser.get_node_data()
			if not stack.empty() and text.length() > 0:
				stack[-1]["text"] = text
		elif node_type == XMLParser.NODE_ELEMENT_END:
			stack.pop()

	if root == null:
		return ""
	return root.to_json()


const PACKED_SCENE_ICON := preload("res://addons/gopilot_utils/textures/PackedScene.png")


func get_class_reference(_class:String) -> String:
	var engine_script_editor = EditorInterface.get_script_editor()
	var engine_edit_tab=engine_script_editor.get_child(0).get_child(1).get_child(1).get_child(0)
	var currently_open_script_tab:Control
	var help_already_open:bool = false
	for i:Control in engine_edit_tab.get_children():
		if i.visible:
			currently_open_script_tab = i
		if i.get_class()=="EditorHelp" and i.name == _class:
			help_already_open = true
	
	engine_script_editor.goto_help(_class)
	var script:Script = engine_script_editor.get_current_script()
	var text:String
	for i in engine_edit_tab.get_children():
		if i.get_class()=="EditorHelp" and i.name == _class:
			var engine_edit_help:RichTextLabel=i.get_child(0)
			text = engine_edit_help.get_parsed_text()
			print(text)
			if script:
				EditorInterface.edit_script(script)
			if not help_already_open:
				i.queue_free()
			break
	if currently_open_script_tab:
		currently_open_script_tab.show()
	if !text.is_empty():
		return text
	return text


func create_inherited_scene(inherits: PackedScene, root_name := "Scene") -> PackedScene:
	var scene := PackedScene.new()
	scene._bundled = { "names": [root_name], "variants": [inherits], "node_count": 1, "nodes": [-1, -1, 2147483647, 0, -1, 0, 0], "conn_count": 0, "conns": [], "node_paths": [], "editable_instances": [], "base_scene": 0, "version": 3 }
	return scene


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
	
	# Lists
	#"\\d+?\\. (.+?)\\n": "[ol]$1[/ol]",
	#"(?s)(?:^|\\s)(\\[(?:ol]\\n)?(?:\\d+\\..*(?:\\n|$))+(?:\\n?[\\s|$])":"",
	#"(?s)(?:^|\\s)(?:\\n?)?(\\d+\\..*(?:\\n\\d+\\..*)*)(?:\\n|$)":"[ol]\n" + 
#"\\1\n".replace("\\n", "\n").replace("  ", "\n").replace("\\d+\\.", "[*]") + 
#"[/ol]",
	#"- (.+?)$": "[ul]$1[/ul]",
	
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
		code_blocks[code] = code_regex.sub(code_blocks[code], "\n$1").trim_prefix("\n").replace("]", "[rb]")
	
	for text in markdown_texts.size():
		for pattern in patterns:
			var regex := RegEx.new()
			var err := regex.compile(pattern, true)
			if err != OK:
				continue
			var replacement:String = patterns[pattern]
			var result := regex.sub(markdown_texts[text], replacement, true)
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


func json_to_node(json_text: String, expand_interface: bool = true) -> Node:
	var obj := JSON.new()
	var parse_err := obj.parse(json_text)
	if parse_err != OK:
		print("Error line: ", obj.get_error_line(), "\nError message: ", obj.get_error_message())
		return Node.new()
	
	var response = obj.get_data()
	var json: Dictionary
	if obj.data is Array:
		json = obj.data[0]
	elif obj.data is Dictionary:
		json = obj.data
	
	if obj.data.has("Root"):
		json = obj.data["Root"]
	
	var new_node: Node = Node.new()
	
	if json.has("type") and json["type"] in ClassDB.get_class_list():
		new_node = ClassDB.instantiate(json["type"])
	
	if new_node is Control:
		if json.has("expand") and json["expand"] == true:
			pass
		else:
			new_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			new_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var properties:PackedStringArray
	for property in new_node.get_property_list():
		properties.append(property["name"])
	
	for key in json:
		if key in ["type", "children"]:
			continue
		if key in properties:
			new_node.set(key, json[key])
	
	if json.has("children"):
		var children:Array[Node]
		for child:Dictionary in json["children"]:
			children.append(json_to_node(str(child)))
		
		for node in children:
			new_node.add_child(node)
	return new_node


## AI generated. Returns a string representation of a directory tree with the given arguments.[br]
## With defualt arguments, it looks like this:[br]
## [codeblock]
## - some_file.txt
## - some_directory
##     - some_file.txt
##     - some_other_file.txt
## [/codeblock]
func directory_tree_to_string(dir_origin: String = "res://", depth: int = 4, indent: String = "  ", element_prefix: String = "- ", exclude_file_types: PackedStringArray = ["uid"], current_depth:int = 0) -> String:
	var result = ""
	var dir = DirAccess.open(dir_origin)
	if dir_origin.get_file().begins_with("."):
		return ""
	if dir:
		dir.list_dir_begin()

		while current_depth < depth:
			var file_name = dir.get_next()
			if file_name == "":
				break

			var file_path = dir_origin.path_join(file_name)
			var file_extension = file_name.split(".")[-1]

			# Skip files with excluded extensions
			if file_extension in exclude_file_types:
				continue

			result += indent.repeat(current_depth) + element_prefix + file_name + "\n"

			if dir.current_is_dir():
				result += directory_tree_to_string(file_path, depth - 1, indent, element_prefix, exclude_file_types, current_depth + 1)

		dir.list_dir_end()

	return result


func directory_tree_to_string_with_rules(dir_origin: String = "res://", depth: int = 4, indent: String = "  ", element_prefix: String = "- ", file_types_whitelist:PackedStringArray = ["gd", "tscn"], blacklisted_folders:PackedStringArray = ["res://addons"], current_depth:int = 0) -> String:
	if dir_origin in blacklisted_folders:
		return ""
	var result = ""
	var dir = DirAccess.open(dir_origin)
	if dir_origin.get_file().begins_with("."):
		return ""
	if dir:
		dir.list_dir_begin()
		while current_depth < depth:
			var file_name = dir.get_next()
			if file_name == "":
				break

			var file_path = dir_origin.path_join(file_name)
			if "." in file_path:
				var file_extension = file_name.split(".")[-1]

				# Skip files with excluded extensions
				if file_extension not in file_types_whitelist:
					continue

			result += indent.repeat(current_depth) + element_prefix + file_name + "\n"

			if dir.current_is_dir():
				result += directory_tree_to_string_with_rules(file_path, depth - 1, indent, element_prefix, file_types_whitelist, blacklisted_folders, current_depth + 1)

		dir.list_dir_end()

	return result


## Converts a directory tree to a json object with this structure:[br]
## [codeblock]
## {
##    "top_directory": {
##        "some_file.txt": "file",
##        "some_directory": {
##            "some_file.txt": "file",
##            "some_other_file.txt": "file"
##        }
##    }
## }
## [/codeblock]
func directory_tree_to_json(dir_origin: String = "res://", depth: int = 4) -> Dictionary[String, Variant]:
	var json: Dictionary[String, Variant] = {}
	var dir = DirAccess.open(dir_origin)
	
	if dir:
		dir.list_dir_begin()
		var current_depth = 0
		
		while current_depth < depth:
			var file_name = dir.get_next()
			if file_name == "":
				break
			
			var file_path = dir_origin.path_join(file_name)
			if dir.current_is_dir():
				json[file_name] = directory_tree_to_json(file_path, depth - 1)
			else:
				json[file_name] = "file"
		dir.list_dir_end()
	return json


func instantiate_all_classes() -> Array[Variant]:
	var classes:Array[Node] = []
	for _class:String in ClassDB.get_class_list():
		var instance = ClassDB.instantiate(_class)
		if instance:
			classes.append(instance)
	return classes


var gdscript_replacers:Dictionary[RegEx, String] = {
	RegEx.create_from_string(r"connect\([\s]*\"(?<signal_name>[\S]+)\",[\s]*[\S]*,[\s]*\"(?<function_name>[\S]+?)\"[\s]*\)"): r"$1.connect($2)",
}

func gdscript_3_to_4(script:String) -> String:
	for regex in gdscript_replacers:
		if !regex:
			continue
		script = regex.sub(script, gdscript_replacers[regex], true)
	return script



func evaluate_expression(expression:String) -> Variant:
	const SCRIPT_BASE:String = "extends Node\n\nfunc run():\n\treturn "
	var script:GDScript = GDScript.new()
	script.source_code = SCRIPT_BASE + expression
	var reload_error := script.reload()
	if reload_error != OK:
		print("Error reloading script: ", reload_error)
		return null
	var instance:Node = script.new()
	if instance:
		return instance.run()
	else:
		return null
