@tool
extends ConfirmationDialog


func _on_about_to_popup() -> void:
	for child in %Prompts.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	var prompts:Dictionary = get_parent().get_settings()["refactor_prompts"]
	for title:String in prompts:
		var content:String = prompts[title]
		var prompt_element:HBoxContainer = %PromptSample.duplicate()
		prompt_element.get_node("Left/Title").text = title
		prompt_element.get_node("Content").text = content
		prompt_element.show()
		%Prompts.add_child(prompt_element)




func _on_confirmed() -> void:
	var prompts:Dictionary[String, String]
	for prompt_element in %Prompts.get_children():
		prompts[prompt_element.get_node("Left/Title").text] = prompt_element.get_node("Content").text
	get_parent().get_settings()["refactor_prompts"] = prompts


func _on_new_prompt_btn_pressed() -> void:
	var prompt_sample:HBoxContainer = %PromptSample.duplicate()
	%Prompts.add_child(prompt_sample)
	prompt_sample.show()
	
