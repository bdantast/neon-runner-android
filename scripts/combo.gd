extends Node

signal combo_changed(count: int, multiplier: float)
signal combo_broke

var combo_count := 0
var combo_multiplier := 1.0
var combo_timer := 0.0
const COMBO_TIMEOUT := 3.0
const COMBO_TIERS := [5, 15, 30, 50]
const MULTIPLIER_TIERS := [1.0, 1.5, 2.0, 3.0, 5.0]

func reset():
	combo_count = 0
	combo_multiplier = 1.0
	combo_timer = 0.0

func add_hit():
	combo_count += 1
	combo_timer = COMBO_TIMEOUT
	_update_multiplier()
	combo_changed.emit(combo_count, combo_multiplier)

func _update_multiplier():
	combo_multiplier = MULTIPLIER_TIERS[0]
	for i in range(COMBO_TIERS.size()):
		if combo_count >= COMBO_TIERS[i]:
			combo_multiplier = MULTIPLIER_TIERS[i + 1]

func tick(delta: float):
	if combo_count <= 0:
		return
	combo_timer -= delta
	if combo_timer <= 0.0:
		combo_broke.emit()
		combo_count = 0
		combo_multiplier = 1.0

func get_earned_energy(base_energy: int) -> int:
	return int(roundf(float(base_energy) * combo_multiplier))
