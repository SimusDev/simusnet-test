@tool
@icon("res://addons/gopilot_utils/textures/agent_handler_icon.svg")
extends Node
class_name AgentHandler
##@tutorial(Video Tutorial): https://youtu.be/2-jRskTdIR0
## Allows for easy agent integration into your software or game[br]
## Set the [member chat_requester], [member action_handler] and [member action_handler_function] to get started![br]
## You can also set the [member system_prompt_format] to change the system prompt format used to guide the LLMs agentic generation[br]
## The [b]action_handler[/b] function must take a String (the action String) and return the observation String for the ReAct workflow (Reason -> Act -> Observe -> Reason...)[br]
## Then add all your actions into the [member actions] Array and describe them (for example by showing the arguments, and what the observation will be)[br]
## To finish up, connect the [signal task_finished] signal and optionally the [signal thought_finished], [signal action_finished] and [signal observation_received] signals to catch every part of the loop![br]
## Then finally, give the agent a task!
## The following code assues you did not change the default [member system_prompt], [member actions] and [member example_conversation]
## [codeblock]
##extends Node
##@onready var agent:AgentHandler = $AgentHandler
##
##@export var task:String = "Tell me what 100/2000 is and also 1 / (70 * 80)"
##func _ready():
##    agent.send_message(task)
##    # Connecting step-signals to see the agents status update
##    agent.action_finished.connect(_on_action_finished)
##    agent.observation_received.connect(_on_observation_received)
##    agent.thought_finished.connect(_on_thought_finished)
##    # Waiting for final answer and printing it
##    var final_answer:String = await agent.task_finished
##    print("\nAgents final answer is \"\"\"" + final_answer + "\"\"\"")
##
##func _on_action_finished(action_string):
##    print("[ACTION]" + action_string + "[/ACTION]")
##
##func _on_observation_received(observation:String):
##    print("[OBSERVATION]" + observation + "[/OBSERVATION]")
##
##func _on_thought_finished(thought:String):
##    print("[THOUGHT]" + thought + "[/THOUGHT]")
##
### Handles action string from LLM and returns the observation
##func handle_action(action_string:String) -> String:
##    # Contains all the actions the agent takes under "# Actions" header
##    var observations:PackedStringArray = []
##    var action_array:Array = JSON.parse_string(action_string)
##    for action_dict:Dictionary in action_array:
##        var action_name:String = action_dict["action"]
##        if action_name != "calculate":
##            observations.append("Action '" +  action_name + "' does not exist. Only use 'calculate' action!")
##            continue
##
##        var args:Dictionary = action_dict["args"]
##        var expression_string:String = args["expression"]
##        # The expression class calculates a value from a string!
##        var expression := Expression.new()
##        var expr_error:Error = expression.parse(expression_string)
##        # If there is an error, return that error
##        if expr_error != OK:
##            observations.append("Expression errored with code: '" +  expression.get_error_text() + "'")
##            continue
##
##        # Calculate result from expression
##        var result = expression.execute()
##        if not expression.get_error_text().is_empty():
##            observations.append("Expression executed with error: '" + expression.get_error_text() + "'")
##            continue
##
##        observations.append("Result for '" + expression_string + "': " + str(result))
##
##    var observation_string:String = ";\n".join(observations)
##    return observation_string
##[/codeblock]

## Emitted when the agent switches generation mode. For example, it switches from thought to action
signal generation_type_changed(type:GenerationType)
##@experimental: Currently includes delimiters
## Emitted whenever a new thought token is generated
signal new_thought_token(token:String)
##@experimental: Currently includes delimiters
## Emitted whenever a new action token is generated
signal new_action_token(token:String)
##@experimental: Might include delimiters
## Emitted whenever a new final answer token is generated
signal new_final_answer_token(token:String)

## Emits once an observation is returned from [member action_handler] [member action_handler_function] is returned
signal observation_received(observation:String)
## Emits when a thought block is finished. Includes the observation
signal thought_finished(thought:String)
## Emits when an action is finished and is now proccessing the observation. Includes the thought
signal action_finished(action:String)
## Emits when the task is finished with the final answer
signal task_finished(finished_message:String)

## The [ChatRequester] which handles the LLMs generation
@export var chat_requester:ChatRequester

## Node which will handle the observation output
@export var action_handler:Node

## Name of the function on the [member action_handler] which will handle the observation output[br]
## The method must return the observation for the agent[br]
## If the agent has completed the task, return null or an empty string [code]""[/code]
@export var action_handler_function:String = "handle_action"

## The system prompt format used to guide the LLMs agentic generation[br]
## Keep as default if you want to use this action format:
## [codeblock]
##[
##    {
##        "action": "name_of_the_action",
##        "args": {
##            "name_of_argument": <value of argument>,
##            ...
##        }
##    }
##]
##[/codeblock]
@export_multiline var system_prompt_format:String = """You are an expert agent and perform actions until goal reached

# Actions
{{actions}}

# Format
You're in a loop "Thought" -> "Actions" -> "Observation" -> "Thought" ...
Start with "# Thought" header plan your actions underneath
Then perform the plan under "# Actions" header
Afterwards the "# Observation" header is inserted, providing updates
Once task is finished, after thought section, write "# Final Answer" header with final answer for the user telling them what you did

# Action format
Under "# Actions" header ALWAYS use this JSON format in array
[
{"action": "name_of_the_action", "args": {"arg_name": <arg value>, ...}},
...
]
Keep action amount to minimum in array
Make sure the args ALWAYS have correct type"""

## The actions the agent can perform. There is no predefined format for the actions. The agent will be prompted to use the actions in the format specified in [member system_prompt_format]
@export_multiline var actions:PackedStringArray = [
	"calculate: Calculates a given expression; Args: expression (string, the mathmatical expression to use e.g. 'max(10.0sin(90.0))'); Outputs: Expression result",
]

## A prefix conversation history, alternating between the user and the agents full output[br]
## One example with a task and a response is usually enough to align the agent to the desired behavior
@export_multiline var example_conversation:PackedStringArray = [
	"Calculate How many times PI fits into 100.",
	"""# Thought
I need to calculate how many times the nubmer pi fits into the number 100
This is a rather simple task. I can use calculator to devide 100 by pi to get the solution

# Actions
[
{"action": "calculate", "args": {"expression": "100.0 / 3.14159"}}
]

# Observation
Result for '100.0 / 3.14159': 31.831015505

# Thought
The result from the calculator says 31.831015505. The user likely wants me to tell them the result

# Final Answer
The number pi fits about 32 times into 100."""
]

## Some API providers don't allow you to spam them with requests within a certain timespan[br]
## To solve this, increase this delay and test how high you need to set it
@export var query_delay:float = 0.0

## Change the delimiters for the LLMs responses. Only change if you know what you are doing
@export_group("Delimiters")

## Delimiter for LLMs thoughts. Must be changed if [member system_prompt_format] has been changed to use different thought delimiter
@export_multiline var thought_delimiter:String = "\n\n# Thought\n"

## Delimiter for LLMs actions. Must be changed if [member system_prompt_format] has been changed to include other action delimiter
@export_multiline var action_delimiter:String = "\n\n# Actions\n"

## Delimiter for LLMs observations. Must be changed if [member system_prompt_format] has been changed to include other observation delimiter
@export_multiline var observation_delimiter:String = "\n\n# Observation\n"

@export_multiline var final_answer_delimiter:String = "\n\n# Final Answer\n"

@export_group("Debug")

@export var debug_mode:bool = false


func _ready() -> void:
	clear_conversation()


func send_message(task:String) -> void:
	final_answer = ""
	if !chat_requester:
		push_error("AgentHandler '", name , "': 'chat_requester' not set. Aborting!")
		return
	connect_signals()
	chat_requester.automatically_add_messages = false
	var final_system_prompt = system_prompt_format
	var actions_string:String = ""
	var is_user:bool = true
	
	if chat_requester.conversation.size() < 1 + example_conversation.size():
		for message in example_conversation:
			if is_user:
				conversation.append({"role": "user", "content": message})
			else:
				conversation.append({"role": "assistant", "content": message})
			is_user = !is_user
	conversation.append({"role": "user", "content": task})
	conversation.append({"role": "assistant", "content": thought_delimiter})
	response_since_delimiter = thought_delimiter
	chat_requester.generate_with_conversation(conversation)
	response_since_delimiter = thought_delimiter
	generation_type_changed.emit(GenerationType.THOUGHT)


func stop(disconnect_signals:bool = true):
	if disconnect_signals:
		disconnect_signals()
	if !chat_requester:
		printerr("No ChatRequester assigned. Aborting")
	chat_requester.stop_generation()


## Continues the agent process[br]
## Can ONLY be called when [method stop] was called previously
func continue_generation():
	if !chat_requester:
		printerr("No ChatRequester assigned. Aborting")
		return
	chat_requester.generate_with_conversation(conversation)


## Clears the conversation history. Useful for new tasks!
func clear_conversation():
	var actions_string:String = ""
	for action in actions:
		actions_string += action + "\n"
	conversation = [{"role": "system", "content": system_prompt_format.replace("{{actions}}", actions_string)}]


#region token handler
enum GenerationType {
	THOUGHT,
	ACTION,
	OBSERVATION,
	FINAL_ANSWER
}

var final_answer:String = ""
var generation_type:GenerationType = GenerationType.THOUGHT

## Internal variable. Includes the full full response since the last task update. Read only
var conversation:Array[Dictionary]


func connect_signals():
	if !chat_requester.new_word.is_connected(_on_new_token):
		chat_requester.new_word.connect(_on_new_token)
	if !chat_requester.message_end.is_connected(_on_generation_finished):
		chat_requester.message_end.connect(_on_generation_finished)


func disconnect_signals():
	if chat_requester.new_word.is_connected(_on_new_token):
		chat_requester.new_word.disconnect(_on_new_token)
	if chat_requester.message_end.is_connected(_on_generation_finished):
		chat_requester.message_end.disconnect(_on_generation_finished)


## Internal variable. Includes the response after the last observation. Read only
var response_since_delimiter:String = ""


var unhandled_tokens:String = ""

##Trims any potential delimiter left in the token. Uses [member unhandled_tokens] and clears once no tokens were found[br]
##Handles these cases:[br]
##- partial beginning of delimiters[br]
##- partial ending of delimiter[br]
##- delimiter beginning found at end or delimiter end found in beginning[br]
##The longer the delimiters, the longer this method will take, as it iterates over each delimiters character
func trim_potential_delimiter(token:String) -> String:
	unhandled_tokens += token
	var trimmed_token:String = unhandled_tokens

	var delimiters:PackedStringArray = [observation_delimiter, action_delimiter, thought_delimiter, final_answer_delimiter]
	var includes_delimiter
	for delimiter in delimiters:
		if delimiter in unhandled_tokens:
			includes_delimiter = true
			trimmed_token = unhandled_tokens.replace(delimiter, "")
			unhandled_tokens = ""
	
	if !includes_delimiter:
		for delimiter in delimiters:
			var partial_beginning:String = delimiter
			for char in delimiter.reverse():
				if unhandled_tokens.ends_with(partial_beginning):
					includes_delimiter = true
					trimmed_token = unhandled_tokens.trim_suffix(partial_beginning)
					unhandled_tokens = partial_beginning
					break
				partial_beginning = partial_beginning.trim_suffix(char)
			if includes_delimiter:
				break
		

	if not includes_delimiter:
		unhandled_tokens = ""
	return trimmed_token


## Internal function. Do not call directly
func _on_new_token(token:String) -> void:
	conversation[-1]["content"] += token
	response_since_delimiter += token
	
	var last_type:GenerationType = generation_type
	var has_observation:bool = observation_delimiter in response_since_delimiter
	var has_action:bool = action_delimiter in response_since_delimiter
	var has_task_finished:bool = final_answer_delimiter in response_since_delimiter
	var has_thought:bool = thought_delimiter in response_since_delimiter
	if action_delimiter in response_since_delimiter:
		generation_type = GenerationType.ACTION
	elif observation_delimiter in response_since_delimiter:
		generation_type = GenerationType.OBSERVATION
	elif thought_delimiter in response_since_delimiter:
		generation_type = GenerationType.THOUGHT
	if final_answer_delimiter in response_since_delimiter:
		generation_type = GenerationType.FINAL_ANSWER
	if last_type != generation_type:
		generation_type_changed.emit(generation_type)
		#unhandled_tokens = ""
	var trimmed_token:String = trim_potential_delimiter(token)
	if !trimmed_token.is_empty():
		match generation_type:
			GenerationType.THOUGHT:
				new_thought_token.emit(trimmed_token)
			GenerationType.ACTION:
				new_action_token.emit(trimmed_token)
			GenerationType.FINAL_ANSWER:
				new_final_answer_token.emit(trimmed_token)
				final_answer += token
	
	if has_thought and has_action:
		var thought:String = ""
		if debug_mode:
			print("case 1 string:\n", response_since_delimiter)
		thought = response_since_delimiter.split(action_delimiter)[0].split(thought_delimiter)[-1]
		response_since_delimiter = action_delimiter + response_since_delimiter.split(action_delimiter)[-1]
		thought_finished.emit(thought)
		return
	
	if has_thought and has_task_finished:
		var thought:String = ""
		thought = response_since_delimiter.split(final_answer_delimiter)[0].split(thought_delimiter)[-1]
		response_since_delimiter = final_answer_delimiter
		thought_finished.emit(thought)
		if debug_mode:
			print("case 2")
		return
	
	if has_observation:
		var action:String = response_since_delimiter.split(observation_delimiter)[0].split(action_delimiter)[-1]
		var after_observation_delim:String = action.split(observation_delimiter)[-1]
		action_finished.emit(action)
		if !action_handler.has_method(action_handler_function):
			push_error("AgentHandler '", name , "': 'action_handler' does not have a method called '", action_handler_function, "'. Aborting!")
			return
		chat_requester.stop_generation(false)
		disconnect_signals()
		var observation:String = await action_handler.call(action_handler_function, action)
		connect_signals()
		response_since_delimiter = thought_delimiter
		observation_received.emit(observation)
		conversation[-1]["content"] += observation_delimiter + observation + thought_delimiter
		while true:
			if chat_requester.connected:
				break
			await get_tree().create_timer(0.01).timeout
		await get_tree().create_timer(query_delay).timeout
		chat_requester.generate_with_conversation(conversation)


func _on_generation_finished(message:String):
	if generation_type == GenerationType.FINAL_ANSWER:
		task_finished.emit(response_since_delimiter.split(final_answer_delimiter)[-1])
		disconnect_signals()
		return
	if action_delimiter in response_since_delimiter and not observation_delimiter in response_since_delimiter:
		var action_string:String = response_since_delimiter.split(action_delimiter)[-1]
		# Adding observation delimiter so that _on_new_token handles the action
		response_since_delimiter += observation_delimiter
		_on_new_token("")
		return
	#print("WEIRD STOP ERROR!!!!! PLEASE REPORT\n[CURRENT GENERATION]\n", response_since_delimiter, "\n[/CURRENT GENERATION]")

#endregion


## Sets the available actions. Also updates the system prompt to reflect changes in the actions
func set_actions(_actions:PackedStringArray):
	actions = _actions
	var final_system_prompt = system_prompt_format
	var actions_string:String = ""
	for action in actions:
		actions_string += action + "\n"
	conversation[0]["content"] = final_system_prompt.replace("{{actions}}", actions_string)
