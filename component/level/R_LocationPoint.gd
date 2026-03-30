extends Resource
class_name R_LocationPoint

var level: R_Level
var name: String

static func create_from_spawnpoint(point: CT_SpawnPoint3D) -> R_LocationPoint:
	var new := R_LocationPoint.new()
	new.level = point.get_level().get_resource()
	new.name = point.name
	return new

func simusnet_serialize(serializer: SimusNetCustomSerialization) -> void:
	serializer.pack(level)
	serializer.pack(name)

static func simusnet_deserialize(serializer: SimusNetCustomSerialization) -> void:
	var result: R_LocationPoint = R_LocationPoint.new()
	result.level = serializer.unpack()
	result.name = serializer.unpack()
	serializer.set_result(result)

func to_spawnpoint(_level: LevelInstance) -> CT_SpawnPoint3D:
	for spawn in _level.get_spawnpoints():
		if spawn.name == name:
			return spawn
	return null
