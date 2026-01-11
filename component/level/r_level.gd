class_name R_Level extends Resource

@export var code:StringName = "Level"
@export var prefab:PackedScene

static var _reference_list:Array[R_Level]
static func get_reference_list() -> Array[R_Level]:
	return _reference_list

func register() -> void:
	for ref in _reference_list:
		if ref.code == code:
			SimusDev.console.write_error("Unable to register level '%s': level with code '%s' already registred" % [self, code])
			return
	if _reference_list.has(self):
		SimusDev.console.write_error("Unable to register level '%s': already registred" % [self])
		return
	_begin_register()
	_reference_list.append(self)
	SimusNetRPC.register(
		[
			local_instantiate
		]
	)
	_registred()

func unregister() -> void:
	if not _reference_list.has(self):
		SimusDev.console.write_error("Unable to unregister level '%s': not registred" % [self])
		return
	_begin_unregister()
	_reference_list.erase(self)
	_unregistred()

func _begin_register() -> void:pass
func _begin_unregister() -> void:pass
func _registred() -> void:
	SimusDev.console.write_info("Level registred: %s" % [self])
func _unregistred() -> void:
	SimusDev.console.write_info("Level unregistred: %s" % [self])

func local_instantiate(node:Node) -> void:
	if not prefab:
		SimusDev.console.write_error("Unable to instantiate level '%s': prefab is null" % [self])
		return
	if not is_instance_valid(node):
		SimusDev.console.write_error("Unable to instantiate level '%s': node is not a valid instance" % [self])
		return
	
	var level_prefab:Node = prefab.instantiate()
	node.add_child(level_prefab)

func instantiate(node:Node) -> void:
	if not SimusNetConnection.is_server():
		SimusDev.console.write_error("Unable to instantiate level '%s': not server" % [self])
		return
	SimusNetRPC.invoke_all(
		local_instantiate,
		node
	)
