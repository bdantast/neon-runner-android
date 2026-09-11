extends Node3D

signal collected(position: Vector3)

var speed := 0.0
var _spin := 0.0
var _base_y := 0.0
var _shell: MeshInstance3D

func _ready():
	add_to_group("collectible")
	name = "EnergyCell"
	var area := Area3D.new()
	area.name = "Pickup"
	var shape := CollisionShape3D.new()
	var bs := SphereShape3D.new()
	bs.radius = 0.55
	shape.shape = bs
	area.add_child(shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.5, 1.0, 1.0)
	m.emission_enabled = true
	m.emission = Color(0.0, 1.0, 1.0)
	m.emission_energy_multiplier = 6.0
	sm.material = m
	core.mesh = sm
	add_child(core)

	var halo := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(0.5, 0.03, 0.5)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.0, 0.7, 1.0)
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.albedo_color.a = 0.5
	hm.emission_enabled = true
	hm.emission = Color(0.0, 0.9, 1.0)
	hm.emission_energy_multiplier = 3.0
	hb.material = hm
	halo.mesh = hb
	add_child(halo)

	_base_y = position.y
	_shell = core

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect()

func collect():
	collected.emit(global_position)
	queue_free()

func set_speed(s: float):
	speed = s

func _process(delta):
	position.z += speed * delta
	_spin += delta * 3.0
	rotation.y = _spin
	if _shell:
		_shell.rotation.y = -_spin * 1.5
	position.y = _base_y + sin(_spin * 1.7) * 0.15
	if position.z > 15.0:
		queue_free()