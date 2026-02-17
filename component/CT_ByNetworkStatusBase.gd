@abstract
extends SimusNetNode
class_name CT_ByNetworkStatusBase

enum STATUS {
	SERVER,
	DEDICATED_SERVER,
	CLIENT,
}

@export var status: STATUS = STATUS.SERVER
@export var condition: bool = true

func _network_ready() -> void:
	match status:
		STATUS.DEDICATED_SERVER:
			if SimusNetConnection.is_dedicated_server() == condition:
				_status_success()
				return
		STATUS.SERVER:
			if SimusNetConnection.is_server() == condition:
				_status_success()
				return
		STATUS.CLIENT:
			if SimusNetConnection.is_client() == condition:
				_status_success()
				return
	
	_status_fail()

func _status_success() -> void:
	pass

func _status_fail() -> void:
	pass
