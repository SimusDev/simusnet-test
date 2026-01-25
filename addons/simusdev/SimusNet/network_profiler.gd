extends Control

@onready var up_traffic: Label = %UpTraffic
@onready var down_traffic: Label = %DownTraffic
@onready var total_traffic: Label = %TotalTraffic
@onready var ping: Label = %Ping


func _on_every_second_timeout() -> void:
	if !is_visible_in_tree():
		return
	
	SimusNetProfiler.send_ping_request_to_server()

func _physics_process(delta: float) -> void:
	if !is_visible_in_tree():
		return
	
	up_traffic.text = "Up (↑) : %s/s" % String.humanize_size(SimusNetProfiler.get_up_traffic_per_second())
	down_traffic.text = "Down (↓) : %s/s" % String.humanize_size(SimusNetProfiler.get_down_traffic_per_second())
	total_traffic.text = "Total Traffic (⇄) : %s" % String.humanize_size(SimusNetProfiler.get_total_traffic())
	ping.text = "  Ping (↯) : %s ms" % SimusNetProfiler.get_ping()
