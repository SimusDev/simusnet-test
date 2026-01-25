class_name R_SoundObject extends R_Object

@export var sources: Array[R_SoundSource]

func local_play(parent:Node3D, position:Vector3) -> R_SoundObject:
	if SimusNetConnection.is_dedicated_server():
		return
	SoundInstance3D.local_create(self, parent, position)
	return self

func play(parent:Node3D, position: Vector3 = Vector3.ZERO, pitch:float = 1.0) -> R_SoundObject:
	if SimusNetConnection.is_dedicated_server():
		return
	SoundInstance3D.create(self, parent, position, pitch)
	return self
