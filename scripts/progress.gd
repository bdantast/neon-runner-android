extends Node

const SAVE_PATH := "user://progress.cfg"

var energy_total := 0
var unlocked_maps := ["neon_city"]
var best_scores := {}
var best_times := {}

var _current_map := "neon_city"

func _ready():
	_load()

func _load():
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	energy_total = cfg.get_value("stats", "energy", 0)
	unlocked_maps = cfg.get_value("maps", "unlocked", ["neon_city"])
	best_scores = cfg.get_value("scores", "best", {})
	best_times = cfg.get_value("times", "best", {})

func _save():
	var cfg := ConfigFile.new()
	cfg.set_value("stats", "energy", energy_total)
	cfg.set_value("maps", "unlocked", unlocked_maps)
	cfg.set_value("scores", "best", best_scores)
	cfg.set_value("times", "best", best_times)
	cfg.save(SAVE_PATH)

func add_energy(amount: int):
	energy_total += amount
	_check_unlocks()
	_save()

func _check_unlocks():
	if energy_total >= 5000 and "tokyo_neon" not in unlocked_maps:
		unlocked_maps.append("tokyo_neon")
		print("UNLOCK: Tokyo Neon!")
	if energy_total >= 15000 and "moscow_frost" not in unlocked_maps:
		unlocked_maps.append("moscow_frost")
		print("UNLOCK: Moscow Frost!")

func is_map_unlocked(map_name: String) -> bool:
	return map_name in unlocked_maps

func save_best(map_name: String, score: int, time: float):
	var changed := false
	if map_name not in best_scores or score > best_scores[map_name]:
		best_scores[map_name] = score
		changed = true
	if map_name not in best_times or time < best_times[map_name]:
		best_times[map_name] = time
		changed = true
	if changed:
		_save()

func get_unlock_cost(map_name: String) -> int:
	match map_name:
		"tokyo_neon": return 5000
		"moscow_frost": return 15000
	return 0

func get_map_unlock_progress(map_name: String) -> float:
	var cost := get_unlock_cost(map_name)
	if cost <= 0:
		return 1.0
	return clampf(float(energy_total) / float(cost), 0.0, 1.0)
