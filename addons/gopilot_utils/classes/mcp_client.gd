@tool
extends Node
class_name MCPClient
##@experimental If you can think of a way to make this interaction easier, let me know!
##Do NOT USE THIS!!!!!! This is an early implementation to see if it even works with different MCP servers

## Emitted when the server sends a message to stdout
signal stdout_received(message:String)


## Emitted when the server sends a message to stderr
signal stderr_received(message:String)


## Name of the MCP server. Optional
@export var server_name:String

## Timeout for requests to the server
@export var request_timeout:float = 10.0

@export_category("Command")

## Command to run the MCP server[br]
## Many times, this will be [code]npx[/code] or [code]docker[/code]
@export var base_command:String

## The arguemnts passed to the command[br]
## Additional arguments can be passed into [method start_server]
@export var arguments:PackedStringArray = []


var stdio:FileAccess
var stderr:FileAccess
var pid:int = 0

func _process(delta: float) -> void:
	if stdio:
		stdio.flush()
		var line: String = stdio.get_line()
		if line != "":
			print(line)
			stdout_received.emit(line)
	
	if stderr:
		stderr.flush()
		var line: String = stderr.get_line()
		if line != "":
			print(line)
			stderr_received.emit(line)


## Starts the MCP server[br]
## [param additional_arguments] are appended to the [member arguments]
func start_server(additional_arguments:PackedStringArray = []):
	var std_dict:Dictionary = OS.execute_with_pipe(base_command, arguments + additional_arguments, false)
	stdio = std_dict["stdio"]
	stderr = std_dict["stderr"]
	var pid:int = std_dict["pid"]
	await stderr_received


## Stops the MCP server
func stop_server():
	if OS.is_process_running(pid):
		OS.kill(pid)
	else:
		print("Process is not running")


## Returns a dictionary of tools that can be used to interact with the MCP server
func get_tools() -> Dictionary:
	if not OS.is_process_running(pid):
		return {}
	var json_rpc := JSONRPC.new()
	var request := json_rpc.make_request("tools/list", {}, 1)
	var get_tools_query:String = JSON.stringify(request)
	var tools:Dictionary = {}
	stdio.store_line(get_tools_query)
	stdio.flush()
	var response:String = await stdout_received
	tools = JSON.parse_string(response)["result"]
	return tools
