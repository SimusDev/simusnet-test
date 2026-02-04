extends Control

func _ready() -> void:
	s_GameObjects.clear_registry()
	
	#var packet1: Dictionary = {
		#1001: {1: Vector3.ZERO, 2: Vector3.ZERO},
		#1002: {1: Vector3.ZERO, 2: Vector3.ZERO},
		#1003: {1: Vector3.ZERO, 2: Vector3.ZERO},
		#1004: {1: Vector3.ZERO, 2: Vector3.ZERO},
		#1005: {1: Vector3.ZERO, 2: Vector3.ZERO},
		#1006: {1: Vector3.ZERO, 2: Vector3.ZERO},
		#1007: {1: Vector3.ZERO, 2: Vector3.ZERO},
		#1008: {1: Vector3.ZERO, 2: Vector3.ZERO},
		#1009: {1: Vector3.ZERO, 2: Vector3.ZERO},
		#1010: {1: Vector3.ZERO, 2: Vector3.ZERO},
	#}
	#
	#var packet2: Dictionary = {
		#1001: PackedVector3Array([Vector3.ZERO, Vector3.ZERO]),
		#1002: PackedVector3Array([Vector3.ZERO, Vector3.ZERO]),
		#1003: PackedVector3Array([Vector3.ZERO, Vector3.ZERO]),
		#1004: PackedVector3Array([Vector3.ZERO, Vector3.ZERO]),
		#1005: PackedVector3Array([Vector3.ZERO, Vector3.ZERO]),
		#1006: PackedVector3Array([Vector3.ZERO, Vector3.ZERO]),
		#1007: PackedVector3Array([Vector3.ZERO, Vector3.ZERO]),
		#1008: PackedVector3Array([Vector3.ZERO, Vector3.ZERO]),
		#1009: PackedVector3Array([Vector3.ZERO, Vector3.ZERO]),
		#1010: PackedVector3Array([Vector3.ZERO, Vector3.ZERO]),
	#}
	#
	#print("packet1 SimusNetCompressor: ", SimusNetCompressor.parse(packet1).size())
	#print("packet2 SimusNetCompressor: ", SimusNetCompressor.parse(packet2).size())
	#
