extends Resource
class_name SimusNetConfigBase

var _serializer_blocked_methods: Array[StringName] = []

func flag_serializer_block_method(method: StringName) -> SimusNetConfigBase:
	if !SimusNetSerializer.get_instance().has_method(method):
		push_error("cant find method %s" % method)
		return self
	
	if !_serializer_blocked_methods.has(method):
		_serializer_blocked_methods.append(method)
	
	return self

func flag_serializer_block_all_methods() -> SimusNetConfigBase:
	var script: Script = SimusNetSerializer.get_instance().get_script()
	for method: Dictionary in script.get_script_method_list():
		if method.name.begins_with("_"):
			continue
		
		flag_serializer_block_method(method.name)
	return self

func flag_serializer_unblock_all_methods() -> SimusNetConfigBase:
	for name in _serializer_blocked_methods:
		flag_serializer_unblock_method(name)
	return self

func flag_serializer_unblock_method(method: StringName) -> SimusNetConfigBase:
	if !SimusNetSerializer.get_instance().has_method(method):
		push_error("cant find method %s" % method)
		return self
	
	if _serializer_blocked_methods.has(method):
		_serializer_blocked_methods.erase(method)
	
	return self
