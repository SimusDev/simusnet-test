@tool
extends Window

var table:Array[PackedStringArray] = [["Keys", "en", "de"], ["CLICK", "click", "klick"], ["SURPRISE", "surprise", "überraschung"]]

var file_path:String = "path/to/your/file.txt"

var content:String

var column_nodes:Array[Node] = []


func open_csv_file(path:String, popup:bool = true):
	file_path = path
	content = FileAccess.open(file_path, FileAccess.READ).get_as_text()
	var lines = content.trim_suffix("\n").split("\n")
	var _table:Array[PackedStringArray] = []
	
	for line in lines:
		_table.append(parse_csv_line(line))
	
	update_table(_table)
	table = _table
	
	if popup:
		popup()


func update_table(_table:Array[PackedStringArray] = table):
	for child in %TableRoot.get_children():
		%TableRoot.remove_child(child)
		child.queue_free()
	column_nodes.clear()
	var columns:int = _table[0].size()
	for column in columns:
		var new_col := VBoxContainer.new()
		%TableRoot.add_child(new_col)
		column_nodes.append(new_col)
		if column != columns:
			var spacer := VSeparator.new()
			%TableRoot.add_child(spacer)
	for column in columns:
		for line in _table.size():
			var item := LineEdit.new()
			item.expand_to_text_length = true
			item.text = _table[line][column]
			column_nodes[column].add_child(item)


func parse_csv_line(line: String) -> PackedStringArray:
	var fields:PackedStringArray = []
	var current_field = ""
	var in_quote = false
	var i = 0
	while i < line.length():
		var c = line[i]
		if c == '"':
			if in_quote and i + 1 < line.length() and line[i + 1] == '"':  # Handle double quotes
				current_field += '"'
				i += 1
			else:
				in_quote = not in_quote
		elif c == ',' and not in_quote:
			fields.append(current_field)
			current_field = ""
		else:
			current_field += c
		i += 1
	
	if current_field.length() > 0:
		fields.append(current_field)
	
	# Post-processing to remove leading and trailing quotes
	for n in range(fields.size()):
		fields[n] = fields[n].trim_prefix('"').trim_suffix('"')
	
	return fields

const TRANSLATION_PROMPT := """I will give you some text and you will translate it into {.language}.
RESPOND WITH ONLY THE TRANSLATION AND NOTHING ELSE! DO NOT WRITE ANYTHING AFTER OR BEOFRE YOUR TRANSLATION!"""

const LANGUAGE_PROMPT := """Privide me with the ISO 639-1 language code for {.language}.
RESPOND WITH ONLY THE UNCAPITALIZED CODE AND NOTHING ELSE! DO NOT WRITE ANYTHING AFTER OR BEOFRE YOUR TRANSLATION!"""

var compare_line:int = 1

func _on_translate_btn_pressed() -> void:
	for line in table:
		line.append("")
	%TranslationStatus.set_status("Loading")
	update_table()
	var update_column:Callable = func(line:int, value:String):
		table[line][-1] = value
		update_table()
	var lang_prompt := LANGUAGE_PROMPT.replace("{.language}", %Language.text)
	var lang_code:String = await %GPI.generate(lang_prompt)
	%TranslationStatus.set_status("Writing")
	table[0][-1] = lang_code
	update_table()
	for line in table.size():
		if line == 0:
			continue
		var base_text := table[line][compare_line]
		var trans_prompt := TRANSLATION_PROMPT.replace("{.language}", %Language.text)
		var translation:String = await %GPI.generate(base_text, false, false, false, trans_prompt)
		update_column.call(line, translation.trim_prefix("\"").trim_suffix("\""))
	%TranslationStatus.set_status("Idle")


func save_table_to_csv():
	var final_text := ""
	for line in table:
		for field in line:
			var modified_field = field
			if "\"" in field:
				modified_field.replace("\"", "\"\"")
			if "," in modified_field:
				modified_field = "\"" + modified_field + "\""
			final_text += modified_field
			if field != line[-1]:
				final_text += ","
		final_text += "\n"
	print("Final table, may be saved: \n", final_text)
	FileAccess.open(file_path, FileAccess.WRITE).store_string(final_text)
	EditorInterface.get_resource_filesystem().reimport_files([file_path])





func _on_canceled() -> void:
	%GPI.stop_generation()


func _on_confirmed() -> void:
	print("confirmed something!")
	save_table_to_csv()
	pass # Replace with function body.
