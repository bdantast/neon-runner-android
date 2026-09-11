extends Node3D

const MAPS := [
	{"id": "neon_city", "name": "NEON CITY", "cost": 0, "color": Color(0.0, 0.8, 1.0)},
	{"id": "tokyo_neon", "name": "TOKYO NEON", "cost": 5000, "color": Color(1.0, 0.3, 0.6)},
	{"id": "moscow_frost", "name": "MOSCOW FROST", "cost": 15000, "color": Color(0.7, 0.85, 1.0)},
]

@onready var start_button: Button = $UI/Center/VBox/StartButton

var _current_map_index := 0
var _map_label: Label
var _map_button: Button
var _energy_label: Label
var _reward_button: Button
var _hero: Node3D
var _sway: Node3D

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	_build_ui()
	_update_map_display()
	_add_hero()
	AudioManager.play_music()

func _add_hero():
	_hero = Node3D.new()
	add_child(_hero)
	_hero.position.z = -10.0
	_hero.position.y = 0.5
	_sway = Node3D.new()
	_hero.add_child(_sway)
	var ps: PackedScene = load("res://assets/Astronaut.glb")
	if ps == null:
		return
	var model := Node3D.new()
	_sway.add_child(model)
	model.add_child(ps.instantiate())
	Neon.fit_local(model, 3.0)
	var aps: Array[Node] = _sway.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		var ap := aps[0] as AnimationPlayer
		if ap.has_animation("CharacterArmature|Idle"):
			ap.get_animation("CharacterArmature|Idle").loop_mode = Animation.LOOP_LINEAR
			ap.play("CharacterArmature|Idle")

func _build_ui():
	var vbox: VBoxContainer = $UI/Center/VBox

	_energy_label = Label.new()
	_energy_label.add_theme_font_size_override("font_size", 28)
	_energy_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
	_energy_label.add_theme_color_override("font_outline_color", Color(0.0, 0.3, 0.2, 1.0))
	_energy_label.add_theme_constant_override("outline_size", 4)
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_label.text = "ENERGIA: " + str(Progress.energy_total)
	vbox.add_child(_energy_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	_map_button = Button.new()
	_map_button.custom_minimum_size = Vector2(350, 60)
	_map_button.pressed.connect(_on_map_pressed)
	vbox.add_child(_map_button)

	_map_label = Label.new()
	_map_label.add_theme_font_size_override("font_size", 18)
	_map_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7))
	_map_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_map_label)

	_reward_button = Button.new()
	_reward_button.text = "ASSISTIR AD → +200 ENERGIA"
	_reward_button.custom_minimum_size = Vector2(350, 50)
	_reward_button.pressed.connect(_on_reward_pressed)
	vbox.add_child(_reward_button)

func _on_map_pressed():
	_current_map_index = (_current_map_index + 1) % MAPS.size()
	_update_map_display()

func _update_map_display():
	var m: Dictionary = MAPS[_current_map_index]
	var unlocked: bool = Progress.is_map_unlocked(m.id)
	var progress: float = Progress.get_map_unlock_progress(m.id)
	var cost: int = m.cost

	_map_button.text = m.name
	if unlocked:
		_map_button.modulate = Color.WHITE
		_map_button.text = "★ " + m.name + " ★"
		_map_label.text = "DESBLOQUEADO"
		_map_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.6))
	else:
		_map_button.modulate = Color(0.4, 0.4, 0.5)
		_map_label.text = "LOCKED — %d/%d energia" % [Progress.energy_total, cost]
		_map_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.3))

	_energy_label.text = "ENERGIA: " + str(Progress.energy_total)

func _on_reward_pressed():
	if Ads.available():
		Ads.show_rewarded()
		await get_tree().create_timer(1.5).timeout
		Progress.add_energy(200)
		_update_map_display()
	else:
		_map_label.text = "ADS NÃO DISPONÍVEIS"
		_map_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))

func _on_start_pressed():
	var m: Dictionary = MAPS[_current_map_index]
	if not Progress.is_map_unlocked(m.id):
		_map_label.text = "MAPA BLOQUEADO!"
		_map_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		return
	Progress._current_map = m.id
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _process(_delta):
	if _hero:
		var t := Time.get_ticks_msec() * 0.001
		_sway.rotation.y = sin(t * 0.7) * 0.45
		_hero.position.y = abs(sin(t * 1.3)) * 0.2
		_sway.rotation.x = sin(t * 2.6) * 0.06
