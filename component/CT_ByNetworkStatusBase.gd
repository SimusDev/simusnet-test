@abstract
extends SimusNetNode
class_name CT_ByNetworkStatusBase

enum STATUS {
	SERVER,
	NOT_SERVER,
	DEDICATED_SERVER,
	CLIENT,
}

@export var status: STATUS = STATUS.SERVER

func _network_ready() -> void:
	match status:
		STATUS.DEDICATED_SERVER:
			if SimusNetConnection.is_dedicated_server():
				_status_success()
				return
		STATUS.SERVER:
			if SimusNetConnection.is_server():
				_status_success()
				return
		STATUS.NOT_SERVER:
			if !SimusNetConnection.is_server():
				_status_success()
				return
			
		STATUS.CLIENT:
			if SimusNetConnection.is_client():
				_status_success()
				return
	
	_status_fail()

func _status_success() -> void:
	pass

func _status_fail() -> void:
	pass
