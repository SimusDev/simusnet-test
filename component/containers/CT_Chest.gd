extends Node
class_name CT_Chest

@export var root: Node3D
@export var inventory: CT_Inventory

const OPEN_ACTION: R_InteractAction = preload("uid://xecviu4tcm2e")
const BACKPACK_INTERFACE: PackedScene = preload("uid://pa0ttv4j400k")

func _ready() -> void:
	if !root:
		root = get_parent()
	
	if !root.is_node_ready():
		await root.ready
	
	if !inventory:
		inventory = CT_Inventory.new()
		inventory.name = "ChestInventory"
		inventory.node = root
		root.add_child(inventory)
	
	if root and inventory:
		if root is CollisionObject3D:
			CT_Collisions.set_body_collision(root, CT_Collisions.LAYERS.INTERACTION, true, true)
		
		OPEN_ACTION.append_to(root)
		inventory.backpack_interface = BACKPACK_INTERFACE
