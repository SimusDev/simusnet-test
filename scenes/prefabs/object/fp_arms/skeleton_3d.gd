@tool
class_name IKSkeleton3D extends Skeleton3D

@export var start_at_ready:bool = true

@export_tool_button("Start IK") var st_ik = start_ik
@export_tool_button("Stop IK") var sp_ik = stop_ik

func start_ik() -> void:
	for x in get_children():
		if x is SkeletonIK3D:
			x.start()

func stop_ik() -> void:
	for x in get_children():
		if x is SkeletonIK3D:
			x.stop()


func _ready() -> void:
	if start_at_ready:
		start_ik()
