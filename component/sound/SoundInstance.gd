class_name SoundInstance3D extends Node3D

var net_config:SimusNetRPCConfig

var src_count = -1
var finished_src_count:int = 0 :
	set(val):
		finished_src_count = val
		if finished_src_count >= src_count:
			queue_free()


func _ready() -> void:
	net_config = (
		SimusNetRPCConfig.new()
			.flag_set_channel("sound")
		)
	
	SimusNetRPC.register(
		[
			local_create
		],
		net_config
	)
	
	var sprite:Sprite3D = Sprite3D.new()
	add_child(sprite)
	sprite.texture = load("res://addons/simusdev/icons/AudioStreamWAV.svg")
	sprite.pixel_size = 0.05
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED

static func local_create(res: R_SoundObject, parent:Node3D, pos: Vector3, pitch:float = 1.0) -> void:
	if res.sources.size() == 0:
		return
	
	var inst:SoundInstance3D = SoundInstance3D.new()
	parent.add_child(inst)
	inst.global_position = pos
	
	for source:R_SoundSource in res.sources:
		if not is_src_audible(inst.global_position, source.max_distance):
			continue
		if source.streams.is_empty():
			continue
		
		var src_player:AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		src_player.stream = source.streams.pick_random()
		src_player.pitch_scale = pitch
		src_player.finished.connect(
			func():
				if is_instance_valid(src_player):
					inst.finished_src_count += 1
					src_player.queue_free()
		)
		inst.add_child(src_player)
		src_player.play()

static func create(res: R_SoundObject, parent:Node3D, pos: Vector3, pitch:float = 1.0) -> void:
	SimusNetRPC.invoke_all(
		local_create,
		res,
		parent,
		pos,
		pitch
		)

static func is_src_audible(target_pos: Vector3, max_dist: float) -> bool:
	#return true SUKA
	var viewport:Viewport = Engine.get_main_loop().root.get_viewport()
	if not viewport:
		return false
	
	var listener_pos: Vector3
	var camera = viewport.get_camera_3d()
	
	if camera:
		listener_pos = camera.global_position
	
	return listener_pos.distance_to(target_pos) < max_dist
