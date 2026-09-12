extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $Camera3D
@onready var world = $World
@onready var env: WorldEnvironment = $WorldEnvironment
@onready var score_label: Label = $UI/ScoreLabel
@onready var energy_label: Label = $UI/EnergyLabel
@onready var time_label: Label = $UI/TimeLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var game_over_panel: PanelContainer = $UI/GameOverPanel
@onready var revive_button: Button = $UI/GameOverPanel/VBox/ReviveButton
@onready var final_score: Label = $UI/GameOverPanel/VBox/ScoreValue
@onready var final_best: Label = $UI/GameOverPanel/VBox/BestValue
@onready var final_energy: Label = $UI/GameOverPanel/VBox/EnergyValue
@onready var final_time: Label = $UI/GameOverPanel/VBox/TimeValue

const BASE_SPEED := 10.0
const SPAWN_AHEAD := 95.0
const LEVEL_SECONDS := 30.0
const LEVEL_SPEED_STEP := 0.1
const MAX_SPEED := 45.0
const REVIVE_MAX := 3
const REVIVE_BONUS := 50

const ObstacleScript := preload("res://scripts/obstacle.gd")
const CollectibleScript := preload("res://scripts/collectible.gd")

const COMBO_TIER_COLORS := [Color(1.0, 0.85, 0.3), Color(1.0, 0.6, 0.2), Color(1.0, 0.4, 0.15), Color(1.0, 0.2, 0.3)]

var score := 0
var energy := 0
var high_score := 0
var speed := BASE_SPEED
var distance := 0.0
var run_time := 0.0
var current_map := "neon_city"
var is_game_over := false
var _spawn_timer := 3.0
var _revive_count := 0
var _score_bonus := 0
var _last_milestone := 0
var rng := RandomNumberGenerator.new()
var level := 1
var level_clock := 0.0
var speed_mult := 1.0
var _level_label: Label
var _level_popup: Label
var _combo_label: Label
var _combo_popup: Label
var _last_combo_tier := -1

func _ready():
	hint_label.visible = true
	current_map = Progress._current_map
	world.set_map(current_map)
	env.apply_theme(current_map)
	high_score = int(Progress.best_scores.get(current_map, 0))
	Combo.reset()
	_connect_combo()
	player.died.connect(_on_player_died)
	_setup_level_ui()
	_setup_combo_ui()
	AudioManager.play_music(current_map)
	spawn_initial()

func _setup_combo_ui():
	_combo_label = Label.new()
	_combo_label.add_theme_font_size_override("font_size", 22)
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_combo_label.add_theme_color_override("font_outline_color", Color(0.5, 0.2, 0.0, 1.0))
	_combo_label.add_theme_constant_override("outline_size", 5)
	_combo_label.add_theme_font_size_override("outline_size", 22)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_combo_label.position = Vector2(560, 118)
	_combo_label.size = Vector2(140, 30)
	_combo_label.visible = false
	$UI.add_child(_combo_label)

	_combo_popup = Label.new()
	_combo_popup.add_theme_font_size_override("font_size", 46)
	_combo_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combo_popup.position = Vector2(0, 300)
	_combo_popup.size = Vector2(720, 120)
	_combo_popup.visible = false
	$UI.add_child(_combo_popup)

func _connect_combo():
	Combo.combo_changed.connect(_on_combo_changed)
	Combo.combo_broke.connect(_on_combo_broke)

func _on_combo_changed(count: int, mult: float):
	if count <= 0:
		_combo_label.visible = false
		return
	_combo_label.visible = true
	_combo_label.text = "COMBO %d  x%.1f" % [count, mult]
	if mult > 1.0:
		var tier := int(mult * 2.0 - 1.5)
		var tc: Color = COMBO_TIER_COLORS[clampi(tier, 0, COMBO_TIER_COLORS.size() - 1)]
		_combo_label.add_theme_color_override("font_color", tc)
		if tier != _last_combo_tier:
			_last_combo_tier = tier
			AudioManager.play_combo()
			_show_combo_popup(mult, tc)

func _show_combo_popup(mult: float, c: Color):
	_combo_popup.text = "COMBO x%.1f!" % mult
	_combo_popup.add_theme_color_override("font_color", c)
	_combo_popup.add_theme_color_override("font_outline_color", Color(0.3, 0.0, 0.0, 0.9))
	_combo_popup.add_theme_constant_override("outline_size", 10)
	_combo_popup.modulate = Color(1, 1, 1, 0)
	_combo_popup.visible = true
	var tw := create_tween()
	tw.tween_property(_combo_popup, "modulate:a", 1.0, 0.1)
	tw.tween_interval(0.8)
	tw.tween_property(_combo_popup, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func(): _combo_popup.visible = false)
	_shake(0.08, 0.06)

func _shake(strength_x: float, strength_y: float):
	var tw := create_tween()
	tw.tween_property(camera, "h_offset", randf_range(-strength_x, strength_x), 0.04)
	tw.parallel().tween_property(camera, "v_offset", randf_range(-strength_y, strength_y), 0.04)
	tw.tween_property(camera, "h_offset", 0.0, 0.18)
	tw.parallel().tween_property(camera, "v_offset", 0.0, 0.18)

func _on_combo_broke():
	_last_combo_tier = -1
	_combo_label.visible = false

func _setup_level_ui():
	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", 20)
	_level_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.85))
	_level_label.add_theme_color_override("font_outline_color", Color(0.0, 0.4, 0.5, 1.0))
	_level_label.add_theme_constant_override("outline_size", 6)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.position = Vector2(0, 150)
	_level_label.size = Vector2(720, 40)
	$UI.add_child(_level_label)
	_update_level_label()

	_level_popup = Label.new()
	_level_popup.add_theme_font_size_override("font_size", 34)
	_level_popup.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
	_level_popup.add_theme_color_override("font_outline_color", Color(0.0, 0.5, 0.6, 1.0))
	_level_popup.add_theme_constant_override("outline_size", 10)
	_level_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_popup.position = Vector2(0, 520)
	_level_popup.size = Vector2(720, 140)
	$UI.add_child(_level_popup)
	_level_popup.visible = false

func _update_level_label():
	_level_label.text = "LEVEL %d   ·   SPEED %.1fx" % [level, speed_mult]

func _level_up():
	level += 1
	speed_mult = 1.0 + (level - 1) * LEVEL_SPEED_STEP
	_update_level_label()
	AudioManager.play_levelup()
	_level_popup.text = "LEVEL %d COMPLETO\nSPEED %.1fx" % [level, speed_mult]
	_level_popup.visible = true
	var tw := create_tween()
	tw.tween_property(_level_popup, "modulate:a", 1.0, 0.12)
	tw.tween_interval(1.0)
	tw.tween_property(_level_popup, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): _level_popup.visible = false)

func spawn_initial():
	for i in range(6):
		var c := _spawn_coin(1, -60.0 - i * 5.0)
		c.speed = speed

func _spawn_coin(lane: int, z: float) -> Node3D:
	var coin := CollectibleScript.new()
	coin.position = Vector3([-2.0, 0.0, 2.0][lane], 1.4, z)
	coin.speed = speed
	if current_map == "tokyo_neon":
		coin.model_path = CollectibleScript.MEMORY_ORB
	coin.collected.connect(_on_collected)
	add_child(coin)
	return coin

func _on_collected(pos: Vector3):
	Combo.add_hit()
	var earned: int = Combo.get_earned_energy(1)
	energy += earned
	energy_label.text = str(energy)
	Progress.add_energy(earned)
	AudioManager.play_collect()
	_spawn_coin_burst(pos)
	_show_energy_popup(pos, earned)

func _spawn_coin_burst(pos: Vector3):
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.ZERO
	pm.spread = 180.0
	pm.initial_velocity_min = 1.5
	pm.initial_velocity_max = 4.0
	pm.gravity = Vector3(0, -2, 0)
	pm.scale_min = 0.06
	pm.scale_max = 0.13
	pm.color = Color(0.0, 1.0, 1.0)
	p.process_material = pm
	p.amount = 16
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 1.0
	add_child(p)
	p.global_position = pos

func _show_energy_popup(pos: Vector3, earned: int):
	var world_pos: Vector2 = camera.unproject_position(pos)
	var lbl := Label.new()
	lbl.text = ("+" + str(earned)) if earned > 1 else "+1"
	lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.8, 1.0, 0.8))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.position = world_pos - Vector2(40.0, 0.0)
	$UI.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position", world_pos + Vector2(0, -90.0), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.45).set_delay(0.3)
	tw.tween_callback(lbl.queue_free)

func _process(delta):
	if is_game_over:
		camera.h_offset = randf_range(-0.35, 0.35)
		camera.v_offset = randf_range(-0.25, 0.25)
		return

	run_time += delta
	Ads.add_play_time(delta)
	time_label.text = "%02d:%02d" % [int(run_time / 60.0), int(fmod(run_time, 60.0))]
	Combo.tick(delta)

	level_clock += delta
	if level_clock >= LEVEL_SECONDS:
		level_clock = 0.0
		_level_up()
	speed_mult = 1.0 + (level - 1) * LEVEL_SPEED_STEP
	speed = (BASE_SPEED + score * 0.03) * speed_mult
	speed = min(speed, MAX_SPEED)
	world.set_speed(speed)

	for n in get_tree().get_nodes_in_group("obstacle"):
		n.set_speed(speed)
	for n in get_tree().get_nodes_in_group("collectible"):
		n.set_speed(speed)

	distance += speed * delta
	score = int(distance * 0.5)
	score_label.text = str(score + _score_bonus)
	if score >= _last_milestone + 100:
		_last_milestone = score
		_pulse_score()

	if score > 40 and hint_label.visible:
		hint_label.visible = false

	camera.position.x = lerpf(camera.position.x, player.position.x * 0.7, delta * 6.0)
	camera.position.y = lerpf(camera.position.y, 7.2 + player.position.y * 0.22, delta * 4.0)
	camera.fov = lerpf(camera.fov, 66.0 + (speed - BASE_SPEED) * 0.9, delta * 2.0)

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = randf_range(0.5, 0.9)
		_spawn_wave()

func _pulse_score():
	var tw := create_tween()
	tw.tween_property(score_label, "scale", Vector2(1.5, 1.5), 0.1)
	tw.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and is_game_over:
		match event.keycode:
			KEY_R:
				_on_restart_pressed()
			KEY_ESCAPE:
				_on_menu_pressed()

func _spawn_wave():
	var lanes := [0, 1, 2]
	lanes.shuffle()

	if rng.randf() < 0.45:
		var lane: int = lanes[0]
		var n := rng.randi_range(3, 5)
		for i in range(n):
			var c := _spawn_coin(lane, -SPAWN_AHEAD + i * 4.5)
			c.position.y = 1.2
		return

	var types := ["robo", "richie", "bot"]
	var type: String = types[rng.randi_range(0, types.size() - 1)]
	var count := 1 + (1 if rng.randf() < 0.35 else 0)
	count = mini(count, 2)

	for i in range(count):
		var lane: int = lanes[i]
		var o := ObstacleScript.new()
		o.setup(type, speed)
		o.position = Vector3([-2.0, 0.0, 2.0][lane], 1.8 if type == "bot" else 0.0, -SPAWN_AHEAD + i * 14.0)
		o._base_y = 1.8 if type == "bot" else 0.0
		add_child(o)

	if rng.randf() < 0.3:
		var lane: int = lanes[2]
		var c := _spawn_coin(lane, -SPAWN_AHEAD + 8.0)
		c.position.y = 1.2

func _on_player_died():
	is_game_over = true
	Combo.reset()
	Ads.on_run_ended()
	Engine.time_scale = 0.3
	AudioManager.play_hit()
	_spawn_explosion()
	_shake(0.25, 0.18)

	if score + _score_bonus > high_score:
		high_score = score + _score_bonus
	Progress.save_best(current_map, score + _score_bonus, run_time)

	final_score.text = "SCORE    " + str(score + _score_bonus)
	final_best.text = "BEST        " + str(high_score)
	final_energy.text = "ENERGY   " + str(energy)
	final_time.text = "TIME      " + "%02d:%02d" % [int(run_time / 60.0), int(fmod(run_time, 60.0))]
	revive_button.visible = Ads.available() and _revive_count < REVIVE_MAX
	game_over_panel.visible = true

func _spawn_explosion():
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 9.0
	pm.gravity = Vector3(0, -4, 0)
	pm.scale_min = 0.15
	pm.scale_max = 0.5
	pm.color = Color(1.0, 0.3, 0.3)
	p.process_material = pm
	p.amount = 60
	p.lifetime = 1.2
	p.one_shot = true
	p.explosiveness = 1.0
	add_child(p)
	p.global_position = player.global_position

func _on_restart_pressed():
	Engine.time_scale = 1.0
	Ads.maybe_show_interstitial()
	get_tree().reload_current_scene()

func _on_menu_pressed():
	Engine.time_scale = 1.0
	Ads.maybe_show_interstitial()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_revive_pressed():
	if not Ads.available():
		return
	if _revive_count >= REVIVE_MAX:
		return
	_revive_count += 1
	Ads.show_rewarded()
	_score_bonus += REVIVE_BONUS
	Engine.time_scale = 1.0
	for n in get_tree().get_nodes_in_group(&"obstacle"):
		n.free()
	for n in get_tree().get_nodes_in_group(&"collectible"):
		n.free()
	player.revive()
	camera.h_offset = 0.0
	camera.v_offset = 0.0
	speed = maxf(BASE_SPEED, speed * 0.75)
	game_over_panel.visible = false
	is_game_over = false
	revive_button.visible = _revive_count < REVIVE_MAX