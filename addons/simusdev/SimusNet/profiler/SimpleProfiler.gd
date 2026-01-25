extends Control

@onready var fps: Label = %Fps
@onready var in_traffic: Label = %InTraffic
@onready var out_traffic: Label = %OutTraffic

func _physics_process(delta: float) -> void:
	if !is_visible_in_tree():
		return
	
	fps.text = "%s fps" % Engine.get_frames_per_second()
	in_traffic.text = "in: %s/s, %s/s" % [SimusNetProfiler.get_up_packets_count(), String.humanize_size(SimusNetProfiler.get_up_traffic_per_second()).to_lower()] 
	out_traffic.text = "out: %s/s, %s/s" % [SimusNetProfiler.get_down_packets_count(), String.humanize_size(SimusNetProfiler.get_down_traffic_per_second()).to_lower()] 
	
