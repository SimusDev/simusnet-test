class_name SimusNetServerInfo extends Resource

@export var name:String = "My Server"
@export var icon:Texture = null
@export_multiline() var description:String = "SimusNet Server"
@export_group("Settings")
@export var port:int = 8080
@export var max_players:int = 32
@export var web_site_url:String = ""
@export_dir var content_path:String
@export_group("Broadcasting", "broadcasting")
@export var broadcasting_port:int = 4241
@export var broadcasting_interval:float = 1.0

@export_group("Listener", "listener")
@export var listener_listening_interval:float = 1.0
@export var listener_cleanup_interval:float = 3.0
@export var listener_server_timeout:float = 5.0

func get_as_dictionary() -> Dictionary:
	var dict:Dictionary = {
		"name": name,
		"icon": icon,
		"description": description,
		"port": port,
		"max_players": max_players,
		"web_site_url": web_site_url,
		"content_path": content_path,
		"broadcasting_port": broadcasting_port,
		"broadcasting_interval": broadcasting_interval,
		"listener_listening_interval": listener_listening_interval,
		"listener_cleanup_interval": listener_cleanup_interval,
		"listener_server_timeout": listener_server_timeout,
	}
	return dict
