@tool
extends SD_SettingsAdsSDK
class_name SD_SettingsAdsSDKYandexMobile

@export var medation: bool = false

func get_os_feature_list() -> PackedStringArray:
	return ["yandex_mobile"]
