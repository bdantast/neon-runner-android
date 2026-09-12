extends Node

const INTERSTITIAL_ID := "ca-app-pub-3940256099942544/1033173712"
const REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"

const GAP_SECONDS := 600.0
const MIN_RUNS := 3
const PERSIST_INTERVAL := 5.0

var _plugin: Object = null

var time_played := 0.0
var runs_count := 0
var last_shown := -GAP_SECONDS

var _save_acc := 0.0

func _ready():
	time_played = Progress.ads_time
	runs_count = Progress.ads_runs
	last_shown = Progress.ads_last_shown
	if Engine.has_singleton("AdMob"):
		_plugin = Engine.get_singleton("AdMob")
		_plugin.call("initialize")
		_plugin.call("load_interstitial_ad", INTERSTITIAL_ID)
		_plugin.call("load_rewarded_ad", REWARDED_ID)

func available() -> bool:
	return _plugin != null

func add_play_time(delta: float) -> void:
	if delta <= 0.0:
		return
	time_played += delta
	_save_acc += delta
	if _save_acc >= PERSIST_INTERVAL:
		_save_acc = 0.0
		_persist()

func on_run_ended() -> void:
	runs_count += 1
	_persist()

func can_show_interstitial() -> bool:
	return _plugin != null and runs_count >= MIN_RUNS and time_played - last_shown >= GAP_SECONDS

func maybe_show_interstitial() -> void:
	if can_show_interstitial():
		show_interstitial()
		last_shown = time_played
		_persist()

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

func _persist() -> void:
	Progress.ads_time = time_played
	Progress.ads_runs = runs_count
	Progress.ads_last_shown = last_shown
	Progress.persist_now()