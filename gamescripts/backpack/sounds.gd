extends CT_GameScript

func _ready() -> void:
	EVENT_Inventory.on_inventory_opened.listen(_on_inventory_opened, true)
	EVENT_Inventory.on_inventory_closed.listen(_on_inventory_closed, true)

func _on_inventory_opened(event: EVENT_InventoryOpened) -> void:
	pass

func _on_inventory_closed(event: EVENT_InventoryClosed) -> void:
	pass
