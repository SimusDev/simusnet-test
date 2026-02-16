@tool
extends Area3D
class_name CT_LevelTransition3D

@export_file("*.tres", "*.res") var level: String
@export var spawn_point3d_name: StringName = ""

func _ready() -> void:
	monitorable = false
	
	if Engine.is_editor_hint():
		return
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	var playable: CT_Playable = SD_ECS.find_first_component_by_script(body, [CT_Playable])
	if !playable.is_local():
		return
	
	UI_LevelTransition.set_level(load(level)).show()
	
