extends Control

@onready var total_objects: Label = %TotalObjects
@onready var up_traffic: Label = %UpTraffic
@onready var down_traffic: Label = %DownTraffic

func _ready() -> void:
	update()

func update() -> void:
	total_objects.text = "Total Objects (☐) : %s" % SimusNetSynchronization.get_transforms().size()
	up_traffic.text = "Up (↑) : %s/s" % String.humanize_size(SimusNetProfiler.get_transform_up_traffic_per_second())
	down_traffic.text = "Down (↓) : %s/s" % String.humanize_size(SimusNetProfiler.get_transform_down_traffic_per_second())


func _physics_process(delta: float) -> void:
	if !is_visible_in_tree():
		return
	
	update()
