extends Node3D

var speed := 0.0
var obstacle_type := "robo"
var _bob := 0.0
var _beat := 0.0
var _base_y := 0.0
var _glow_mesh: MeshInstance3D
var _rotor: Node3D

const MAT_RED := Color(1.0, 0.15, 0.15)
const MODEL_PATHS := {
	"robo": "res://assets/Generic Robo dude by Erik Buchholtz - 0wnOYufJaPm.glb",
	"richie": "res://assets/Richie by joney_lol - BwaLw2Olre.glb",
	"bot": "res://assets/Bot Drone by Dave404 - 2iyQx2YscRq.glb",
}
const ENEMY_HEIGHT := {"robo": 1.55, "richie": 2.05, "bot": 1.4}

func setup(type: String, spd: float):
	obstacle_type = type
	speed = spd

func _ready():
	name = obstacle_type
	add_to_group("obstacle")
	build()

func build():
	var area := Area3D.new()
	area.name = "HitArea"
	var shape := CollisionShape3D.new()
	var bs: Shape3D

	if obstacle_type == "bot":
		bs = SphereShape3D.new()
		(bs as SphereShape3D).radius = 0.65
		shape.position = Vector3(0, 0, 0)
	else:
		bs = BoxShape3D.new()
		if obstacle_type == "robo":
			(bs as BoxShape3D).size = Vector3(1.1, 1.7, 0.7)
		else:
			(bs as BoxShape3D).size = Vector3(1.9, 1.8, 1.9)
		shape.position = Vector3(0, 0.85, 0)

	shape.shape = bs
	area.add_child(shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

	if not _attach_model():
		_build_visual_procedural()

func _attach_model() -> bool:
	var path: String = MODEL_PATHS.get(obstacle_type, "")
	if path == "":
		return false
	var ps: PackedScene = load(path)
	if ps == null:
		return false
	var inst: Node3D = ps.instantiate()
	add_child(inst)
	var h: float = ENEMY_HEIGHT.get(obstacle_type, 1.5)
	Neon.fit_local(inst, h)
	match obstacle_type:
		"robo":
			inst.rotation.y = PI
			_glow_mesh = _make_eye(Vector3(0.0, h + 0.04, 0.16))
		"richie":
			_glow_mesh = _make_eye(Vector3(0.0, h * 0.6, 0.75))
		_:
			inst.rotation.y = randf() * TAU
			_glow_mesh = _make_eye(Vector3(0.0, 0.05, 0.4))
	Neon.tint_dark(inst, Color(0.6, 0.46, 0.54))
	_rotor = null
	return true

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.die()

func _mat(albedo: Color, emissive: Color, energy: float, rough := 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = rough
	m.metallic = 0.6
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emissive
		m.emission_energy_multiplier = energy
	return m

func _box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat
	mi.mesh = bm
	parent.add_child(mi)
	mi.position = pos
	return mi

func _blade_tip(blade: MeshInstance3D, mat: StandardMaterial3D):
	for sy in [-0.9, 0.9]:
		var tip := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.1
		sm.height = 0.2
		sm.material = mat
		tip.mesh = sm
		tip.position = Vector3(0, sy, 0)
		blade.add_child(tip)

func _make_eye(pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.11
	sm.height = 0.22
	sm.material = _mat(Color(0.0, 0.0, 0.0), MAT_RED, 6.0)
	mi.mesh = sm
	add_child(mi)
	mi.position = pos
	return mi

func _build_visual_procedural():
	var dark := _mat(Color(0.02, 0.02, 0.06), Color(0.012, 0.0, 0.0), 0.15)
	var metal := _mat(Color(0.08, 0.04, 0.05), Color(0.05, 0.0, 0.0), 0.3)
	var red := _mat(Color(0.35, 0.02, 0.02), MAT_RED, 3.2)
	var red_soft := _mat(Color(0.18, 0.02, 0.03), MAT_RED, 1.6)

	if obstacle_type == "bot":
		var shell := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.6
		sp.height = 1.2
		sp.material = dark
		shell.mesh = sp
		add_child(shell)
		_glow_mesh = _box(self, Vector3(0.5, 0.5, 0.5), red, Vector3(0, 0, 0.18))
		_rotor = Node3D.new()
		add_child(_rotor)
		for ang in [0.0, PI / 2.0]:
			var blade := Node3D.new()
			blade.rotation.y = ang
			var thin := _box(blade, Vector3(0.08, 1.9, 0.12), metal, Vector3(0, 0, 0))
			_blade_tip(thin, red_soft)
			_rotor.add_child(blade)
	else:
		if obstacle_type == "robo":
			_box(self, Vector3(0.55, 1.5, 0.5), dark, Vector3(0, 0.78, 0))
			_box(self, Vector3(0.62, 0.2, 0.55), metal, Vector3(0, 0.35, 0))
			_box(self, Vector3(0.14, 0.5, 0.06), red, Vector3(-0.16, 0.7, 0.26))
			_box(self, Vector3(0.14, 0.5, 0.06), red, Vector3(0.16, 0.7, 0.26))
			_box(self, Vector3(0.3, 0.28, 0.3), dark, Vector3(0, 1.55, 0))
			_glow_mesh = _make_eye(Vector3(0, 1.62, 0.16))
		else:
			_box(self, Vector3(1.9, 0.3, 0.55), dark, Vector3(0, 1.52, 0))
			_box(self, Vector3(0.26, 1.5, 0.5), dark, Vector3(-0.82, 0.78, 0))
			_box(self, Vector3(0.26, 1.5, 0.5), dark, Vector3(0.82, 0.78, 0))
			_box(self, Vector3(1.9, 0.12, 0.52), red, Vector3(0, 1.28, 0))
			_box(self, Vector3(0.1, 0.9, 0.06), red_soft, Vector3(-0.82, 0.85, 0.26))
			_box(self, Vector3(0.1, 0.9, 0.06), red_soft, Vector3(0.82, 0.85, 0.26))
			_glow_mesh = _make_eye(Vector3(0, 1.62, 0.2))

func _process(delta):
	position.z += speed * delta
	_beat += delta * 9.0
	if obstacle_type == "bot":
		_bob += delta * 3.0
		position.y = _base_y + sin(_bob) * 0.12
		rotation.y += delta * 2.2
		if _rotor:
			_rotor.rotation.y += delta * 6.0
	if _glow_mesh:
		var pw: float = 0.5 + 0.5 * sin(_beat)
		var sc := 0.92 + 0.16 * pw
		_glow_mesh.scale = Vector3(sc, sc, sc)
	if position.z > 15.0:
		queue_free()

func set_speed(s: float):
	speed = s
