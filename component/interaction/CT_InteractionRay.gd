@tool
extends RayCast3D
class_name CT_InteractionRay

@export var root: Node3D

const INPUT: StringName = &"interact"

var _ui: UI_InteractActions

func _ready() -> void:
	collide_with_areas = true
	collide_with_bodies = true
	
	set_collision_mask_value(CT_Collisions.LAYERS.INTERACTION, true)
	
	set_physics_process(false)
	
	if Engine.is_editor_hint():
		return
	
	SimusNetNodeAutoVisible.register_or_get(self)
	
	SimusNetRPC.register(
		[
			_server_action
		], SimusNetRPCConfig.new()
		.flag_mode_any_peer()
		.flag_serialization()
		.flag_set_channel(Network.CHANNEL_INVENTORY)
	)
	
	SimusNetRPC.register(
		[
			_local_action
		], SimusNetRPCConfig.new()
		.flag_mode_server_only()
		.flag_serialization()
		.flag_set_channel(Network.CHANNEL_INVENTORY)
	)
	
	if !root.is_node_ready():
		await root.ready
	
	if not SimusNet.is_network_authority(self) and not SimusNetConnection.is_server():
		process_mode = Node.PROCESS_MODE_DISABLED
		queue_free()
		return
	
	if root is CollisionObject3D:
		add_exception(root)
	
	var playable: CT_Playable = CT_Playable.find_in(root)
	if playable and SimusNet.is_network_authority(self):
		await _initialize_ui()
		

func _initialize_ui() -> void:
	_ui = await R_UI.find_by_id("ui:interact_actions").async_get_instance()
	_ui.hide()
	_ui.set_mode(UI_InteractActions.MODE.INTERACTION)
	_ui.on_selected.connect(_on_action_selected)
	set_physics_process(true)

func _on_action_selected(action: R_InteractAction) -> void:
	SimusNetRPC.invoke_on_server(_server_action, action)

func _server_action(action: R_InteractAction) -> void:
	if get_collider():
		action._server_selected_world(get_collider(), self)
		SimusNetRPC.invoke_all(_local_action, action)

func _local_action(action: R_InteractAction) -> void:
	pass

var _prev_collider: Object = null
func _physics_process(delta: float) -> void:
	if !is_instance_valid(_ui):
		return
	
	_ui.visible = is_instance_valid(get_collider())
	
	if _prev_collider == get_collider():
		return
	
	_collider_changed()
	_prev_collider = get_collider()

func _collider_changed() -> void:
	if !get_collider():
		return
	
	var actions: Array[R_InteractAction] = R_InteractAction.get_from(get_collider())
	_ui.set_actions(actions)
