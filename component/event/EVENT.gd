@static_unload
extends SD_Event
class_name EVENT

#func publish(arguments: Variant = null) -> bool:
	#debug = false
	#return super(arguments)

func set_properties(data: Dictionary[String, Variant]) -> EVENT:
	for p in data:
		set(p, data[p])
	return self

static var on_player_spawned := EVENT_PlayerSpawned.new()
static var on_player_despawned := EVENT_PlayerDespawned.new()
static var on_player_spawned_local := EVENT_PlayerSpawned.new()
static var on_player_despawned_local := EVENT_PlayerDespawned.new()
static var on_inventory_opened := EVENT_InventoryOpened.new()
static var on_inventory_closed := EVENT_InventoryClosed.new()
static var on_inventory_ready := EVENT_InventoryReady.new()
static var on_inventory_ready_local := EVENT_InventoryReadyLocal.new()
