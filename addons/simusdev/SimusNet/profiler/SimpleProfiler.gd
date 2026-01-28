extends Control

@onready var fps: Label = %Fps
@onready var in_traffic: Label = %InTraffic
@onready var out_traffic: Label = %OutTraffic
@onready var ping: Label = %Ping

func _physics_process(delta: float) -> void:
	if !is_visible_in_tree():
		return
	
	fps.text = "%s fps" % Engine.get_frames_per_second()
	out_traffic.text = "in: %s/s, %s/s" % [SimusNetProfiler.get_up_packets_count(), String.humanize_size(SimusNetProfiler.get_up_traffic_per_second()).to_lower()] 
	in_traffic.text = "out: %s/s, %s/s" % [SimusNetProfiler.get_down_packets_count(), String.humanize_size(SimusNetProfiler.get_down_traffic_per_second()).to_lower()] 
	ping.text = "ping: %s ms" % [SimusNetProfiler.get_ping()]

func _on_timer_timeout() -> void:
	SimusNetProfiler.send_ping_request_to_server()
