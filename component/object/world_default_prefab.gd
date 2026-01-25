extends RigidBody3D

@onready var object: I_WorldObject = I_WorldObject.find_in(self)

func _ready() -> void:
	if object:
		if object.get_object():
			$Sprite3D.texture = object.get_object().get_icon()
	
