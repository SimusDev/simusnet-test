extends RigidBody3D

@onready var object: I_WorldObject = I_WorldObject.find_in(self)

func _ready() -> void:
	if object:
		$Sprite3D.texture = object.get_icon()
	
