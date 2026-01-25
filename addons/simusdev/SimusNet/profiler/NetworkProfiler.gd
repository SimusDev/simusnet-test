extends Control

@onready var up_packets: Label = %UpPackets
@onready var down_packets: Label = %DownPackets
@onready var up_traffic: Label = %UpTraffic
@onready var down_traffic: Label = %DownTraffic
@onready var total_traffic: Label = %TotalTraffic
@onready var ping: Label = %Ping

func _on_every_second_timeout() -> void:
	if !is_visible_in_tree():
		return
	
	SimusNetProfiler.send_ping_request_to_server()

func _ready() -> void:
	update()

func update() -> void:
	up_packets.text = "Packets (↑): %s/s" % str(SimusNetProfiler.get_up_packets_count())
	down_packets.text = "Packets (↓): %s/s" % str(SimusNetProfiler.get_down_packets_count())
	up_traffic.text = "   Traffic (↑) : %s/s" % String.humanize_size(SimusNetProfiler.get_up_traffic_per_second())
	down_traffic.text = "   Traffic (↓) : %s/s" % String.humanize_size(SimusNetProfiler.get_down_traffic_per_second())
	total_traffic.text = "   Total Traffic (⇄) : %s" % String.humanize_size(SimusNetProfiler.get_total_traffic())
	ping.text = "   Ping (↯) : %s ms" % SimusNetProfiler.get_ping()


func _physics_process(delta: float) -> void:
	if !is_visible_in_tree():
		return
	
	update()

func _on_close_draw() -> void:
	queue_free()
