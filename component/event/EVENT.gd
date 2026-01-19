@static_unload
extends SD_Event
class_name EVENT

#func publish(arguments: Variant = null) -> bool:
	#debug = false
	#return super(arguments)

static var on_player_spawned := EVENT_PlayerSpawned.new()
static var on_player_despawned := EVENT_PlayerDespawned.new()
static var on_player_spawned_local := EVENT_PlayerSpawned.new()
static var on_player_despawned_local := EVENT_PlayerDespawned.new()
