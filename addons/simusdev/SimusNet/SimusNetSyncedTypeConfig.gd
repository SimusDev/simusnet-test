extends RefCounted
class_name SimusNetSyncedTypeConfig

enum MODE {
	AUTHORITY,
	SERVER_ONLY,
	TO_SERVER,
}

var _mode: MODE = MODE.AUTHORITY

var _serialization: bool = false

func flag_mode_authority() -> SimusNetSyncedTypeConfig:
	_mode = MODE.AUTHORITY
	return self

func flag_mode_server_only() -> SimusNetSyncedTypeConfig:
	_mode = MODE.SERVER_ONLY
	return self

func flag_mode_to_server() -> SimusNetSyncedTypeConfig:
	_mode = MODE.TO_SERVER
	return self

func flag_serialization(value: bool = true) -> SimusNetSyncedTypeConfig:
	_serialization = value
	return self
