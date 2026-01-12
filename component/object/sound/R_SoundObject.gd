class_name R_SoundObject extends R_Object

@export var sources: Array[R_SoundSource]

func local_play(parent:Node3D, position:Vector3) -> void:
	if SimusNetConnection.is_dedicated_server():
		return
	SoundInstance3D.create(self, parent, position)

func play(parent:Node3D, position: Vector3 = Vector3.ZERO) -> void:
	if SimusNetConnection.is_server():
		SimusNetRPC.invoke_all(
			local_play,
			parent,
			position,
			)
