extends Control

func _ready() -> void:
	#var packet1: Dictionary = {
		#1000: Transform3D(),
		#1001: Transform3D(),
		#1002: Transform3D(),
		#1003: Transform3D(),
		#1004: Transform3D(),
		#1005: Transform3D(),
		#1006: Transform3D(),
	#}
	#
	#var packet2: Dictionary = {
		#1000: SimusNetCompressor.parse(Transform3D()),
		#1001: SimusNetCompressor.parse(Transform3D()),
		#1002: SimusNetCompressor.parse(Transform3D()),
		#1003: SimusNetCompressor.parse(Transform3D()),
		#1004: SimusNetCompressor.parse(Transform3D()),
		#1005: SimusNetCompressor.parse(Transform3D()),
		#1006: SimusNetCompressor.parse(Transform3D()),
	#}
	#
	#print("packet1: ", SimusNetCompressor.parse(packet1).size())
	#print("packet2: ", SimusNetCompressor.parse(packet2).size())
	s_GameObjects.clear_registry()
