class_name SoundInstance3D extends Node3D

var src_count:int = 0
var finished_src_count:int = 0 :
	set(val):
		finished_src_count = val
		if finished_src_count == src_count:
			queue_free()

static func create(res: R_SoundObject, parent:Node3D, pos: Vector3) -> void:
	var inst:SoundInstance3D = SoundInstance3D.new()
	parent.add_child(inst)
	inst.global_position = pos
	for source in res.sources:
		if not is_src_audible(pos, source.max_distance):
			continue
		
		var src_player:AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		inst.src_count += 1
		src_player.stream = source.streams.pick_random()
		src_player.finished.connect(
			func():
				if is_instance_valid(src_player):
					src_player.queue_free()
					inst.finished_src_count += 1
		)
		inst.add_child(src_player)
		src_player.play()

static func is_src_audible(target_pos: Vector3, max_dist: float) -> bool:
	var viewport:Viewport = Engine.get_main_loop().root.get_viewport()
	if not viewport: return false
	
	var listener_pos: Vector3
	var camera = viewport.get_camera_3d()
	
	if camera:
		listener_pos = camera.global_position
	
	return listener_pos.distance_squared_to(target_pos) < (max_dist * max_dist)
