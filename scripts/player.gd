extends CharacterBody3D

signal died

const GRAVITY := 32.0
const JUMP_FORCE := 14.0
const BUFFER_TIME := 0.15
const LANE_X := [-2.0, 0.0, 2.0]
const ASTRONAUT_SCENE := "res://assets/Astronaut.glb"
const HERO_HEIGHT := 4.0
const COLLIDE_H := 4.0
const SLIDE_H := 1.0

var lane := 1
var grounded := false
var dead := false
var slide_timer := 0.0
var anim_time := 0.0

var _cs: CollisionShape3D
var _cs_shape: BoxShape3D
var _visual: Node3D
var _rig: Node3D
var _model: Node3D
var _squash_node: Node3D
var _ap: AnimationPlayer
var _jump_held := false
var _buffer := 0.0
var _squash := 0.0
var _trail: CPUParticles3D
var _dust: CPUParticles3D

func _ready():
	add_to_group("player")
	_cs = $CollisionShape3D
	_cs_shape = BoxShape3D.new()
	_cs_shape.size = Vector3(0.6, COLLIDE_H, 0.6)
	_cs.shape = _cs_shape
	_cs.position.y = COLLIDE_H * 0.5
	_build_soldier()
	_setup_effects()

func _setup_effects():
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.0, 0.9, 1.0)
	glow.light_energy = 2.2
	glow.omni_range = 3.0
	glow.position = Vector3(0.0, 1.8, -0.15)
	add_child(glow)

	_trail = CPUParticles3D.new()
	_trail.amount = 22
	_trail.lifetime = 0.5
	_trail.direction = Vector3(0, -1, 0)
	_trail.spread = 25.0
	_trail.gravity = Vector3(0, -1, 0)
	_trail.initial_velocity_min = 0.2
	_trail.initial_velocity_max = 0.8
	_trail.scale_amount_min = 0.05
	_trail.scale_amount_max = 0.11
	_trail.color = Color(0.1, 0.9, 1.0, 0.5)
	_trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_trail.emission_sphere_radius = 0.16
	_trail.position = Vector3(0, 0.1, -0.25)
	add_child(_trail)

	_dust = CPUParticles3D.new()
	_dust.amount = 16
	_dust.lifetime = 0.45
	_dust.one_shot = true
	_dust.explosiveness = 1.0
	_dust.direction = Vector3(0, 1, 0)
	_dust.spread = 60.0
	_dust.gravity = Vector3(0, -3, 0)
	_dust.initial_velocity_min = 1.0
	_dust.initial_velocity_max = 2.5
	_dust.scale_amount_min = 0.08
	_dust.scale_amount_max = 0.16
	_dust.color = Color(0.5, 0.9, 1.0, 0.55)
	_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_dust.emission_sphere_radius = 0.2
	_dust.position = Vector3(0, 0.08, 0)
	add_child(_dust)

func _build_soldier():
	_visual = Node3D.new()
	_visual.name = "Hero"
	add_child(_visual)
	_rig = Node3D.new()
	_visual.add_child(_rig)
	_model = Node3D.new()
	_rig.add_child(_model)
	_squash_node = Node3D.new()
	_model.add_child(_squash_node)
	var ps: PackedScene = load(ASTRONAUT_SCENE)
	if ps == null:
		return
	var model := ps.instantiate()
	_squash_node.add_child(model)
	_visual.rotation = Vector3(0, PI, 0)
	Neon.fit(_model, HERO_HEIGHT)
	var aps: Array[Node] = _visual.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		_ap = aps[0] as AnimationPlayer
		_ap.speed_scale = 1.5
		_play_anim("Run")

func _play_anim(name: String):
	if _ap and _ap.has_animation("CharacterArmature|" + name):
		if name == "Run" or name == "Roll":
			_ap.get_animation("CharacterArmature|" + name).loop_mode = Animation.LOOP_LINEAR
		_ap.play("CharacterArmature|" + name)

func _unhandled_input(event):
	if dead:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT:
				_change_lane(-1)
			KEY_RIGHT:
				_change_lane(1)
			KEY_SPACE, KEY_UP:
				_jump()
			KEY_DOWN:
				_start_slide()
	elif event is InputEventKey and not event.pressed:
		match event.keycode:
			KEY_SPACE, KEY_UP:
				_jump_held = false
	elif event is InputEventScreenTouch:
		_handle_touch(event)

var _drag_start := Vector2.ZERO
var _dragging := false

func _handle_touch(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			_drag_start = event.position
			_dragging = true
			_jump_held = true
		else:
			_jump_held = false
			if _dragging:
				_dragging = false
				_swipe(event.position - _drag_start)

func _swipe(d: Vector2):
	if d.length() < 50.0:
		return
	if abs(d.x) > abs(d.y):
		_change_lane(1 if d.x > 0 else -1)
	elif d.y < 0:
		_jump()
	else:
		_start_slide()

func _change_lane(dir: int):
	lane = clampi(lane + dir, 0, 2)

func _jump():
	_jump_held = true
	_buffer = BUFFER_TIME

func _do_jump():
	if not grounded:
		return
	velocity.y = JUMP_FORCE
	grounded = false

func _start_slide():
	if grounded:
		slide_timer = 0.55
		_cs_shape.size = Vector3(0.6, SLIDE_H, 0.6)
		_cs.position.y = SLIDE_H * 0.5
		_play_anim("Roll")

func _physics_process(delta):
	if dead:
		return

	if slide_timer > 0.0:
		slide_timer -= delta
		if slide_timer <= 0.0:
			_cs_shape.size = Vector3(0.6, COLLIDE_H, 0.6)
			_cs.position.y = COLLIDE_H * 0.5
			_play_anim("Run")

	var was_grounded := grounded
	grounded = is_on_floor()

	if _buffer > 0.0:
		_buffer -= delta
		if grounded and _jump_held:
			_do_jump()
			_buffer = 0.0

	if not grounded:
		velocity.y -= GRAVITY * delta
		if not _jump_held and velocity.y > 0.0:
			velocity.y -= GRAVITY * delta * 1.6
	else:
		velocity.y = 0.0

	if not was_grounded and grounded:
		_on_landing()

	var target_x: float = LANE_X[lane]
	var dx: float = target_x - position.x
	velocity.x = dx * 16.0
	rotation.z = lerpf(rotation.z, -velocity.x * 0.012, delta * 12.0)

	move_and_slide()
	grounded = is_on_floor()
	_trail.emitting = grounded
	anim_time += delta
	_animate(delta)

func _on_landing():
	_squash = 1.0
	if not dead:
		_dust.restart()
		_dust.emitting = true

func _animate(delta):
	if _squash > 0.0:
		_squash = maxf(_squash - delta * 4.0, 0.0)
	var sq := 1.0 - _squash * 0.25
	var sx := 1.0 + _squash * 0.18
	scale = Vector3(sx, sq, sx)

	if _visual == null:
		return

	if _squash_node != null:
		_squash_node.scale = Vector3(1.0, 0.5 if slide_timer > 0.0 else 1.0, 1.0)

	var t := anim_time
	if grounded:
		var hop: float = (sin(t * 11.0) * 0.5 + 0.5) * 0.09
		var sway: float = sin(t * 5.5) * 0.05
		_visual.position.y = hop
		_rig.rotation.y = lerpf(_rig.rotation.y, sway * 0.5, delta * 8.0)
		_rig.rotation.x = lerpf(_rig.rotation.x, -0.14, delta * 10.0)
	else:
		_visual.position.y = 0.0
		_rig.rotation.y = lerpf(_rig.rotation.y, 0.0, delta * 8.0)
		_rig.rotation.x = lerpf(_rig.rotation.x, -0.22, delta * 8.0)

	if dead:
		_rig.rotation.z = lerpf(_rig.rotation.z, 0.4, delta * 6.0)

func die():
	if dead:
		return
	dead = true
	_disable_collision()
	_play_anim("Death")
	emit_signal("died")

func _disable_collision():
	_cs.set_deferred("disabled", true)
	velocity = Vector3.ZERO

func revive():
	dead = false
	_cs.disabled = true
	position = Vector3(LANE_X[1], 0.0, 0.0)
	velocity = Vector3.ZERO
	grounded = true
	slide_timer = 0.0
	_cs_shape.size = Vector3(0.6, COLLIDE_H, 0.6)
	_cs.position.y = COLLIDE_H * 0.5
	_cs.disabled = false
	rotation.z = 0.0
	_play_anim("Run")
