extends Resource
class_name R_LocationPoint

var level: R_Level
var name: String

static func create_from_spawnpoint(point: CT_SpawnPoint3D) -> R_LocationPoint:
	var new := R_LocationPoint.new()
	new.level = point.get_level().get_resource()
	new.name = point.name
	return new

func serialize() -> Dictionary:
	var result: Dictionary = {}
	result[0] = SimusNetSerializer.parse_resource(level)
	result[1] = name
	return result

static func deserialize(data: Dictionary) -> R_LocationPoint:
	var result := R_LocationPoint.new()
	result.level = SimusNetDeserializer.parse_resource(data[0])
	result.name = data[1]
	return result

func to_spawnpoint(_level: LevelInstance) -> CT_SpawnPoint3D:
	for spawn in _level.get_spawnpoints():
		if spawn.name == name:
			return spawn
	return null
