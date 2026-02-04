extends Node3D
class_name SpawnableObjects

static var _instance: SpawnableObjects

const CAMERA_RAYCAST_RANGE: float = 100.0

func _ready() -> void:
	_instance = self
	SimusNetRPC.register([
		_request_spawn_rpc,
		_request_undo_rpc,
	],
	SimusNetRPCConfig.new().flag_mode_any_peer().
	flag_set_channel(Network.CHANNEL_INVENTORY)
	)

func _input(event: InputEvent) -> void:
	if SimusDev.ui.has_active_interface():
		return
	
	if Input.is_action_just_pressed("spawner.undo"):
		request_undo()

static func server_get_undo_queue(user: CT_User) -> Array[Node]:
	if user.has_meta("undo_queue"):
		var old: Array[Node] = user.get_meta("undo_queue")
		var new: Array[Node] = []
		
		for i in old:
			if is_instance_valid(i):
				new.append(i)
		
		user.set_meta("undo_queue", new)
		return new 
	var result: Array[Node] = []
	user.set_meta("undo_queue", result)
	return result

static func request_spawn_from_camera(object: R_WorldObject, quantity: int = 1, inventory: bool = false) -> void:
	var camera: Camera3D = _instance.get_tree().root.get_camera_3d()
	if !camera:
		return
	
	var result: Dictionary = SD_Raycasting3D.intersect_ray_from_node(camera, CAMERA_RAYCAST_RANGE)
	if result:
		var collider: Object = result.collider
		if collider:
			var pos: Vector3 = result.position
			request_spawn(object, pos, quantity, inventory)
			return

static func request_spawn(object: R_WorldObject, global_position: Vector3, quantity: int = 1, inventory: bool = false) -> void:
	var user: CT_User = CT_User.get_local()
	if user:
		SimusNetRPC.invoke_on_server(_instance._request_spawn_rpc,
		object,
		LevelInstance.get_current(),
		global_position, 
		quantity, 
		inventory)

func _request_spawn_rpc(object: R_WorldObject, level: LevelInstance, global_position: Vector3, quantity: int, inventory: bool) -> void:
	var user: CT_User = CT_User.find_by_peer(SimusNetRemote.sender_id)
	if !is_instance_valid(user):
		return
	
	if !is_instance_valid(level):
		return
	
	if inventory:
		var player: Node = user.get_player_node()
		if is_instance_valid(player):
			var player_inventory: CT_Inventory = CT_Inventory.find_in(player)
			if player_inventory:
				var item: CT_ItemStack = CT_ItemStack.create_from_object(object)
				if object.get_itemstack_config().stackable:
					item.quantity = quantity
					player_inventory.try_add_item(item)
				else:
					for i in quantity:
						player_inventory.try_add_item(item)
				
				item.queue_free()
			
	else:
		var instance: Node = I_WorldObject.new(level, object).instantiate().get_instance()
		if is_instance_valid(instance):
			instance.global_position = global_position
			CT_ItemStack.find_or_create_gamestate_stack_reference_in(instance).quantity = quantity
			server_get_undo_queue(user).append(instance)

static func request_undo() -> void:
	var user: CT_User = CT_User.get_local()
	if user:
		SimusNetRPC.invoke_on_server(_instance._request_undo_rpc)

func _request_undo_rpc() -> void:
	var user: CT_User = CT_User.find_by_peer(SimusNetRemote.sender_id)
	if !is_instance_valid(user):
		return
	
	var queue: Array[Node] = server_get_undo_queue(user)
	if queue.is_empty():
		return
	
	var picked: Node = queue.get(queue.size() - 1)
	picked.queue_free()
