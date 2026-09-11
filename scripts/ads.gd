extends Node

const INTERSTITIAL_ID := "ca-app-pub-3940256099942544/1033173712"
const REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"

var _plugin: Object = null

func _ready():
	if Engine.has_singleton("AdMob"):
		_plugin = Engine.get_singleton("AdMob")
		_plugin.call("initialize")
		_plugin.call("load_interstitial_ad", INTERSTITIAL_ID)
		_plugin.call("load_rewarded_ad", REWARDED_ID)

func available() -> bool:
	return _plugin != null

func show_interstitial() -> void:
	if _plugin == null:
		return
	_plugin.call("show_interstitial_ad")
	_plugin.call("load_interstitial_ad", INTERSTITIAL_ID)

func show_rewarded() -> void:
	if _plugin == null:
		return
	_plugin.call("show_rewarded_ad")
	_plugin.call("load_rewarded_ad", REWARDED_ID)