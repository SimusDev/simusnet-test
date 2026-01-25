extends Control

@onready var total_objects: Label = %TotalObjects
@onready var up_traffic: Label = %UpTraffic
@onready var down_traffic: Label = %DownTraffic

func _ready() -> void:
	update()

func _physics_process(delta: float) -> void:
	if !is_visible_in_tree():
		return
	
	update()

func update() -> void:
	total_objects.text = "Total Traffic (⇄) : %s" % String.humanize_size(SimusNetProfiler.get_visibility_total_traffic())
	up_traffic.text = "Sent %s Objects (↑) : %s" % [SimusNetProfiler.get_visibility_sent_count(), String.humanize_size(SimusNetProfiler.get_visibility_up_traffic())]
	down_traffic.text = "Received %s Objects (↓) : %s" % [SimusNetProfiler.get_visibility_received_count(), String.humanize_size(SimusNetProfiler.get_visibility_down_traffic())]
