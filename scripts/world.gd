extends Node3D

var speed := 5.0
var rng := RandomNumberGenerator.new()
var current_map := "neon_city"

var _divider_dashes: Array[MeshInstance3D] = []
var _buildings_l: Array[Node3D] = []
var _buildings_r: Array[Node3D] = []
var _people: Array[Node3D] = []
var _cars: Array[Node3D] = []
var _tron_walls: Array[Node3D] = []
var _snow_node: GPUParticles3D
var _props: Array[Node3D] = []
var _arches: Array[Node3D] = []

const K_GLB := "res://assets/kenney_city-kit-commercial_2.1/Models/GLB format/"
const K_BUILDINGS := ["building-a", "building-b", "building-c", "building-d", "building-e",
	"building-f", "building-g", "building-h", "building-i", "building-j",
	"building-k", "building-l", "building-m", "building-n"]
const K_SKYSCRAPERS := ["building-skyscraper-a", "building-skyscraper-b", "building-skyscraper-c",
	"building-skyscraper-d", "building-skyscraper-e"]
const K_LOW := ["low-detail-building-a", "low-detail-building-b", "low-detail-building-c",
	"low-detail-building-d", "low-detail-building-e", "low-detail-building-f",
	"low-detail-building-g", "low-detail-building-h", "low-detail-building-i",
	"low-detail-building-j", "low-detail-building-k", "low-detail-building-l",
	"low-detail-building-m", "low-detail-building-n", "low-detail-building-wide-a",
	"low-detail-building-wide-b"]
const K_VEHICLES := ["res://assets/Spaceship by Quaternius - u105mYHLHU.glb",
	"res://assets/x-wing by Alberto Calvo - d6Xadlg51aC.glb",
	"res://assets/Spaceship by Quaternius - uCeLfsdmNP.glb",
	"res://assets/Drone by NateGazzard - DNbUoMtG3H.glb"]
const TRON_PATH := "res://assets/troncityscape1 #FV7 by Fragmastre TV - 4o0bLgk8mhD.glb"
const RU_GLB := "res://assets/kenney_retro-urban-kit/Models/GLB format/"
const CYBER_GLB := "res://assets/Cyberpunk Platform by Quaternius - "
const CYBER_SIGN := "res://assets/Cyberpunk Signs by Quaternius - rsZJjigt1X.glb"
const K_DETAIL := ["detail-awning", "detail-awning-wide", "detail-overhang",
	"detail-overhang-wide", "detail-parasol-a", "detail-parasol-b"]
const RU_WALLS := ["wall-a", "wall-a-window", "wall-a-flat", "wall-a-detail",
	"wall-a-door", "wall-a-garage", "wall-b", "wall-b-window", "wall-b-flat", "wall-type-a"]

const BUILD_LEFT_X := -14.5
const BUILD_RIGHT_X := 14.5
const BUILD_SPAN := 220.0
const BUILD_FAR := -160.0
const BUILD_NEAR := 60.0
const BUILD_COUNT := 42
const DASH_SPACING := 5.0
const DASH_COUNT := 18
const SIDEWALK_X := 7.7
const TRON_WALL_X := 132.0

var mat_road: StandardMaterial3D
var mat_curb: StandardMaterial3D
var mat_divider: StandardMaterial3D
var mat_rail: StandardMaterial3D
var mat_roof: StandardMaterial3D
var mat_band: StandardMaterial3D

var _tint := Color(1.0, 1.0, 1.0)
var _road_a := Color(0.85, 0.9, 1.0)
var _curb_a := Color(0.0, 0.28, 0.4)
var _curb_e := Color(0.0, 0.7, 1.0)
var _curb_en := 1.3
var _div_a := Color(0.0, 0.4, 0.5)
var _div_e := Color(0.0, 0.9, 1.0)
var _div_en := 1.8
var _rail_a := Color(0.02, 0.02, 0.06)
var _rail_e := Color(0.5, 0.15, 1.0)
var _rail_en := 1.1
var _roof_a := Color(0.3, 0.0, 0.45)
var _roof_e := Color(0.9, 0.3, 1.0)
var _roof_en := 2.6
var _band_a := Color(0.0, 0.2, 0.32)
var _band_e := Color(0.0, 0.75, 1.0)
var _band_en := 1.4
var _people_palette: Array = [Color(0.2, 0.1, 0.3), Color(0.15, 0.0, 0.25), Color(0.05, 0.15, 0.3), Color(0.25, 0.05, 0.2)]
var _veh_glow := Color(0.3, 0.9, 1.0)
var _veh_lamp := Color(0.4, 0.9, 1.0)
var _use_tron := false
var _use_snow := false

func _ready():
	rng.randomize()
	_apply_theme()
	_build_materials()
	_build_road()
	_build_dividers()
	_build_sidewalks()
	_build_buildings()
	_build_people()
	_build_cars()
	_build_arches()
	_build_props()

func _apply_theme():
	match current_map:
		"tokyo_neon":
			_tint = Color(1.25, 1.0, 1.5)
			_road_a = Color(0.45, 0.18, 0.5)
			_curb_a = Color(0.3, 0.0, 0.26)
			_curb_e = Color(1.0, 0.2, 0.85)
			_curb_en = 1.4
			_div_a = Color(0.32, 0.0, 0.22)
			_div_e = Color(1.0, 0.3, 0.95)
			_div_en = 1.9
			_rail_a = Color(0.06, 0.01, 0.09)
			_rail_e = Color(0.9, 0.2, 1.0)
			_rail_en = 1.3
			_roof_a = Color(0.42, 0.0, 0.32)
			_roof_e = Color(1.0, 0.2, 0.8)
			_roof_en = 2.7
			_band_a = Color(0.2, 0.0, 0.22)
			_band_e = Color(0.4, 0.9, 1.0)
			_band_en = 1.6
			_people_palette = [Color(0.4, 0.1, 0.35), Color(0.9, 0.3, 0.6), Color(0.2, 0.35, 0.45), Color(0.5, 0.15, 0.3)]
			_veh_glow = Color(1.0, 0.35, 0.8)
			_veh_lamp = Color(1.0, 0.45, 0.9)
			_use_tron = true
			_use_snow = false
		"moscow_frost":
			_tint = Color(1.3, 1.33, 1.65)
			_road_a = Color(0.65, 0.72, 0.9)
			_curb_a = Color(0.2, 0.4, 0.6)
			_curb_e = Color(0.5, 0.85, 1.0)
			_curb_en = 1.2
			_div_a = Color(0.25, 0.5, 0.65)
			_div_e = Color(0.7, 0.95, 1.0)
			_div_en = 1.7
			_rail_a = Color(0.03, 0.04, 0.1)
			_rail_e = Color(0.5, 0.8, 1.0)
			_rail_en = 1.2
			_roof_a = Color(0.2, 0.35, 0.5)
			_roof_e = Color(0.6, 0.9, 1.0)
			_roof_en = 2.5
			_band_a = Color(0.12, 0.26, 0.38)
			_band_e = Color(0.6, 0.95, 1.0)
			_band_en = 1.5
			_people_palette = [Color(0.1, 0.2, 0.3), Color(0.4, 0.45, 0.6), Color(0.15, 0.25, 0.4), Color(0.3, 0.35, 0.5)]
			_veh_glow = Color(0.6, 0.9, 1.0)
			_veh_lamp = Color(0.8, 0.95, 1.0)
			_use_tron = false
			_use_snow = true
		_:
			_tint = Color(1.1, 1.15, 1.4)
			_road_a = Color(0.85, 0.9, 1.0)
			_curb_a = Color(0.0, 0.28, 0.4)
			_curb_e = Color(0.0, 0.7, 1.0)
			_curb_en = 1.3
			_div_a = Color(0.0, 0.4, 0.5)
			_div_e = Color(0.0, 0.9, 1.0)
			_div_en = 1.8
			_rail_a = Color(0.02, 0.02, 0.06)
			_rail_e = Color(0.5, 0.15, 1.0)
			_rail_en = 1.1
			_roof_a = Color(0.3, 0.0, 0.45)
			_roof_e = Color(0.9, 0.3, 1.0)
			_roof_en = 2.6
			_band_a = Color(0.0, 0.2, 0.32)
			_band_e = Color(0.0, 0.75, 1.0)
			_band_en = 1.4
			_people_palette = [Color(0.2, 0.1, 0.3), Color(0.15, 0.0, 0.25), Color(0.05, 0.15, 0.3), Color(0.25, 0.05, 0.2)]
			_veh_glow = Color(0.3, 0.9, 1.0)
			_veh_lamp = Color(0.4, 0.9, 1.0)
			_use_tron = false
			_use_snow = false

func _build_materials():
	mat_road = StandardMaterial3D.new()
	mat_road.albedo_texture = _road_texture()
	mat_road.albedo_color = _road_a
	mat_road.roughness = 0.45
	mat_road.metallic = 0.15
	mat_road.uv1_scale = Vector3(6.0, 1.0, 60.0)

	mat_curb = StandardMaterial3D.new()
	mat_curb.albedo_color = _curb_a
	mat_curb.emission_enabled = true
	mat_curb.emission = _curb_e
	mat_curb.emission_energy_multiplier = _curb_en

	mat_divider = StandardMaterial3D.new()
	mat_divider.albedo_color = _div_a
	mat_divider.emission_enabled = true
	mat_divider.emission = _div_e
	mat_divider.emission_energy_multiplier = _div_en

	mat_rail = StandardMaterial3D.new()
	mat_rail.albedo_color = _rail_a
	mat_rail.emission_enabled = true
	mat_rail.emission = _rail_e
	mat_rail.emission_energy_multiplier = _rail_en

	mat_roof = StandardMaterial3D.new()
	mat_roof.albedo_color = _roof_a
	mat_roof.emission_enabled = true
	mat_roof.emission = _roof_e
	mat_roof.emission_energy_multiplier = _roof_en

	mat_band = StandardMaterial3D.new()
	mat_band.albedo_color = _band_a
	mat_band.emission_enabled = true
	mat_band.emission = _band_e
	mat_band.emission_energy_multiplier = _band_en

func _road_texture() -> ImageTexture:
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.035, 0.04, 0.06))
	for y in range(0, 256, 32):
		img.fill_rect(Rect2i(0, y, 256, 2), Color(0.085, 0.095, 0.13))
	for y in range(0, 256, 4):
		var v: float = 0.02 + rng.randf() * 0.04
		img.fill_rect(Rect2i(0, y, 256, 1), Color(v, v * 1.1, v * 1.4))
	for i in range(900):
		var x := rng.randi_range(0, 255)
		var y := rng.randi_range(0, 255)
		var sp: float = 0.02 + rng.randf() * 0.05
		img.set_pixel(x, y, Color(sp, sp * 1.15, sp * 1.5))
	for i in range(28):
		var y := rng.randi_range(4, 250)
		var x0 := rng.randi_range(0, 220)
		img.fill_rect(Rect2i(x0, y, rng.randi_range(14, 46), 1), Color(0.0, 0.18, 0.24, 0.5))
	for y in range(256):
		img.set_pixel(255, y, img.get_pixel(0, y))
	return ImageTexture.create_from_image(img)

func _make_mat(albedo: Color, emissive: Color, energy: float, rough := 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = rough
	m.metallic = 0.35
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

func _build_road():
	var sb := StaticBody3D.new()
	sb.name = "GroundCollision"
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(14.0, 0.5, 420.0)
	cs.shape = bs
	cs.position = Vector3(0.0, -0.25, 0.0)
	sb.add_child(cs)
	sb.position = Vector3(0.0, 0.0, 0.0)
	add_child(sb)
	_box(self, Vector3(14.0, 0.5, 420.0), mat_road, Vector3(0.0, -0.25, 0.0))
	_box(self, Vector3(0.14, 0.07, 420.0), mat_curb, Vector3(-6.15, 0.035, 0.0))
	_box(self, Vector3(0.14, 0.07, 420.0), mat_curb, Vector3(6.15, 0.035, 0.0))
	_box(self, Vector3(0.5, 1.0, 420.0), mat_rail, Vector3(-7.0, 0.0, 0.0))
	_box(self, Vector3(0.5, 1.0, 420.0), mat_rail, Vector3(7.0, 0.0, 0.0))

func _build_dividers():
	var start := -DASH_COUNT * DASH_SPACING / 2.0
	for side in [-1.0, 1.0]:
		for i in range(DASH_COUNT):
			var seg := _box(self, Vector3(0.07, 0.02, 1.2), mat_divider,
				Vector3(side, 0.015, start + i * DASH_SPACING))
			_divider_dashes.append(seg)

func _build_sidewalks():
	var sb_mat := _make_mat(Color(0.05, 0.05, 0.1), Color.BLACK, 0.0, 0.95)
	var edge_mat := _make_mat(Color(0.02, 0.02, 0.06), _rail_e, 1.2)
	_box(self, Vector3(1.6, 0.16, 420.0), sb_mat, Vector3(-SIDEWALK_X, 0.08, 0.0))
	_box(self, Vector3(1.6, 0.16, 420.0), sb_mat, Vector3(SIDEWALK_X, 0.08, 0.0))
	_box(self, Vector3(0.08, 0.22, 420.0), edge_mat, Vector3(-7.0, 0.11, 0.0))
	_box(self, Vector3(0.08, 0.22, 420.0), edge_mat, Vector3(7.0, 0.11, 0.0))
	var front_sb := _make_mat(Color(0.07, 0.07, 0.13), Color.BLACK, 0.0, 0.9)
	_box(self, Vector3(2.8, 0.16, 420.0), front_sb, Vector3(-10.6, 0.08, 0.0))
	_box(self, Vector3(2.8, 0.16, 420.0), front_sb, Vector3(10.6, 0.08, 0.0))
	_box(self, Vector3(0.1, 0.04, 420.0), mat_curb, Vector3(-9.15, 0.18, 0.0))
	_box(self, Vector3(0.1, 0.04, 420.0), mat_curb, Vector3(9.15, 0.18, 0.0))

func _build_buildings():
	for i in range(BUILD_COUNT):
		_buildings_l.append(_make_building(true, i))
		_buildings_r.append(_make_building(false, i))

func _slot_z(slot: int) -> float:
	return BUILD_FAR + slot * (BUILD_SPAN / float(BUILD_COUNT)) + randf_range(-1.0, 1.0)

func _make_building(left: bool, slot: int) -> Node3D:
	var holder := Node3D.new()
	holder.position = Vector3(BUILD_LEFT_X if left else BUILD_RIGHT_X, 0.0, _slot_z(slot))
	holder.rotation.y = rng.randi_range(0, 1) * PI
	add_child(holder)
	_install_building(holder)
	return holder

func _random_building_path() -> String:
	var r: float = rng.randf()
	if current_map == "tokyo_neon":
		if r < 0.4:
			return K_GLB + K_SKYSCRAPERS[rng.randi_range(0, K_SKYSCRAPERS.size() - 1)] + ".glb"
		return K_GLB + K_BUILDINGS[rng.randi_range(0, K_BUILDINGS.size() - 1)] + ".glb"
	if current_map == "moscow_frost":
		if r < 0.5:
			return K_GLB + K_LOW[rng.randi_range(0, K_LOW.size() - 1)] + ".glb"
		elif r < 0.85:
			return K_GLB + K_BUILDINGS[rng.randi_range(0, K_BUILDINGS.size() - 1)] + ".glb"
		return K_GLB + K_SKYSCRAPERS[rng.randi_range(0, K_SKYSCRAPERS.size() - 1)] + ".glb"
	if r < 0.52:
		return K_GLB + K_BUILDINGS[rng.randi_range(0, K_BUILDINGS.size() - 1)] + ".glb"
	elif r < 0.78:
		return K_GLB + K_SKYSCRAPERS[rng.randi_range(0, K_SKYSCRAPERS.size() - 1)] + ".glb"
	return K_GLB + K_LOW[rng.randi_range(0, K_LOW.size() - 1)] + ".glb"

func _install_building(holder: Node3D):
	for c in holder.get_children():
		c.free()
	holder.position.y = 0.0
	var ps: PackedScene = load(_random_building_path())
	var inst := ps.instantiate()
	holder.add_child(inst)
	Neon.tint_dark(inst, _tint)
	holder.rotation.y = rng.randi_range(0, 1) * PI
	var base_h: float = Neon.aabb(holder).size.y
	if base_h <= 0.001:
		base_h = 1.5
	var target: float = randf_range(12.0, 34.0)
	if current_map == "tokyo_neon":
		target = randf_range(22.0, 48.0)
	elif current_map == "moscow_frost":
		target = randf_range(8.0, 22.0)
	var depth: float = randf_range(6.2, 7.2)
	inst.scale = Vector3(depth, target / base_h, depth)
	var bb: AABB = Neon.aabb(holder)
	holder.position.y = -bb.position.y
	var max_halfx := 14.5 - 9.8
	var halfx: float = bb.size.x * 0.5
	if halfx > max_halfx:
		inst.scale.x *= max_halfx / halfx
	_attach_building_accents(holder, bb)

func _attach_building_accents(holder: Node3D, bb: AABB):
	var h: float = bb.size.y
	var base: float = bb.position.y
	_box(holder, Vector3(randf_range(4.6, 6.0), 0.06, 0.4), mat_roof, Vector3(0.0, base + h - 0.6, 0.0))
	var band := _box(holder, Vector3(randf_range(4.8, 6.2), h * 0.035, 0.5), mat_band,
		Vector3(0.0, base + h * 0.45, 0.0))
	if rng.randf() < 0.45:
		band.position.y = base + h * 0.62

func _rand_spawn_z() -> float:
	return randf_range(-48.0, 25.0)

func _recycle_building(b: Node3D):
	b.position.z = BUILD_FAR - randf_range(0.0, 8.0)
	_install_building(b)

func _build_people():
	for i in range(8):
		var p := _make_person(_people_palette[i % _people_palette.size()])
		p.position = Vector3(SIDEWALK_X * (1.0 if i < 4 else -1.0), 0.15, randf_range(-45.0, 20.0))
		p.rotation.y = rng.randf_range(-0.3, 0.3)
		_people.append(p)
		add_child(p)

func _make_person(co: Color) -> Node3D:
	var p := Node3D.new()
	var dark := _mat(Color(0.06, 0.06, 0.1), Color.BLACK, 0.0)
	var skin := _make_mat(Color(0.28, 0.22, 0.2), Color.BLACK, 0.0)
	var hair := _make_mat(Color(0.05, 0.05, 0.08), co, 2.6)
	var jacket_mat := _make_mat(co, Color(0.4, 0.0, 0.8), 0.8)

	_box(p, Vector3(0.05, 0.38, 0.06), dark, Vector3(-0.055, 0.19, 0))
	_box(p, Vector3(0.05, 0.38, 0.06), dark, Vector3(0.055, 0.19, 0))
	_box(p, Vector3(0.26, 0.42, 0.15), jacket_mat, Vector3(0, 0.69, 0))
	_box(p, Vector3(0.16, 0.16, 0.16), skin, Vector3(0, 1.02, 0))
	_box(p, Vector3(0.22, 0.05, 0.16), hair, Vector3(0, 1.16, -0.01))
	_box(p, Vector3(0.27, 0.12, 0.03), _make_mat(Color(0.35, 0.6, 1.0), Color(0.2, 0.5, 1.0), 1.6), Vector3(0, 0.98, 0.08))
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(0.17 * side, 0.9, 0)
		_box(arm, Vector3(0.05, 0.3, 0.055), jacket_mat, Vector3(0, -0.15, 0))
		_box(arm, Vector3(0.04, 0.1, 0.05), skin, Vector3(0, -0.34, 0))
		p.add_child(arm)
	return p

func _vehicle_path() -> String:
	return K_VEHICLES[rng.randi_range(0, K_VEHICLES.size() - 1)]

func _rebuild_vehicle(v: Node3D):
	for c in v.get_children():
		c.free()
	var ps: PackedScene = load(_vehicle_path())
	var inst := ps.instantiate()
	v.add_child(inst)
	var size: Vector3 = Neon.aabb(v).size
	var s: float = 2.2 / maxf(maxf(size.x, size.z), 0.001)
	inst.scale = Vector3.ONE * s
	var glow := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	sm.material = _mat(Color(0.0, 0.0, 0.0), _veh_glow, 5.0)
	glow.mesh = sm
	glow.position = Vector3(0.0, -0.35, 0.45)
	v.add_child(glow)
	var lamp := OmniLight3D.new()
	lamp.light_color = _veh_lamp
	lamp.light_energy = 1.4
	lamp.omni_range = 4.2
	lamp.omni_attenuation = 1.6
	lamp.position = Vector3(0.0, -0.5, 0.2)
	v.add_child(lamp)
	v.set_meta("_glow", glow)
	v.set_meta("_lamp", lamp)

func _build_cars():
	for i in range(6):
		var v := Node3D.new()
		v.set_meta("slot", i)
		var bx: float = rng.randf_range(-3.4, 3.4)
		var by: float = rng.randf_range(6.0, 11.0)
		var ph: float = rng.randf() * TAU
		v.set_meta("_bx", bx)
		v.set_meta("_by", by)
		v.set_meta("_ph", ph)
		add_child(v)
		_rebuild_vehicle(v)
		v.position = Vector3(bx, by, _car_slot(i))
		_cars.append(v)

func _car_slot(i: int) -> float:
	return -85.0 + i * 16.0 + randf_range(-1.5, 1.5)

func _mat(albedo: Color, emissive: Color, energy: float) -> StandardMaterial3D:
	return _make_mat(albedo, emissive, energy)

func _add_glb(parent: Node3D, path: String, scale: float, pos: Vector3, rot_y := 0.0) -> Node3D:
	var ps: PackedScene = load(path)
	if ps == null:
		return null
	var inst := ps.instantiate()
	parent.add_child(inst)
	inst.scale = Vector3.ONE * scale
	inst.position = pos
	inst.rotation.y = rot_y
	return inst

func _build_arches():
	for a in _arches:
		a.free()
	_arches.clear()
	if current_map != "tokyo_neon":
		return
	var n := 7
	var step := 19.0
	var start := -84.0
	for i in range(n):
		var arch := Node3D.new()
		arch.position = Vector3(0.0, 0.0, start + i * step)
		add_child(arch)
		_box(arch, Vector3(0.42, 5.8, 0.42), mat_rail, Vector3(-6.45, 2.9, 0.0))
		_box(arch, Vector3(0.42, 5.8, 0.42), mat_rail, Vector3(6.45, 2.9, 0.0))
		_box(arch, Vector3(13.5, 0.5, 0.5), mat_curb, Vector3(0.0, 5.6, 0.0))
		_box(arch, Vector3(2.4, 0.65, 0.2), mat_band, Vector3(0.0, 4.75, 0.0))
		_arches.append(arch)

func _build_props():
	for p in _props:
		p.free()
	_props.clear()
	var missions := {"neon_city": 22, "tokyo_neon": 28, "moscow_frost": 24}
	var count: int = missions.get(current_map, 22)
	for i in range(count):
		var prop := Node3D.new()
		add_child(prop)
		_make_prop(prop)
		_props.append(prop)

func _make_prop(prop: Node3D):
	prop.rotation.y = 0.0
	var side: float = 1.0 if rng.randf() < 0.5 else -1.0
	prop.position.x = side * randf_range(7.6, 9.2)
	prop.position.y = 0.0
	prop.position.z = randf_range(-88.0, 24.0)
	var jz: float = rng.randf_range(5.0, 18.0)
	if rng.randf() < 0.35:
		jz *= -1.0
	prop.set_meta("_jz", jz)
	if current_map == "moscow_frost":
		_prop_moscow(prop)
	elif current_map == "tokyo_neon":
		_prop_tokyo(prop)
	else:
		_prop_neon(prop)

func _prop_moscow(prop: Node3D):
	var kind: float = rng.randf()
	if kind < 0.3:
		var inst := _add_glb(prop, RU_GLB + "detail-light-single.glb", randf_range(4.0, 5.2),
			Vector3.ZERO, rng.randf() * TAU)
		if inst != null:
			var lamp := OmniLight3D.new()
			lamp.light_color = Color(1.0, 0.9, 0.72)
			lamp.light_energy = 2.4
			lamp.omni_range = 8.0
			lamp.omni_attenuation = 1.7
			inst.add_child(lamp)
			lamp.position = Vector3(0.0, 3.4, 0.0)
	elif kind < 0.58:
		var t := "tree-pine-large" if rng.randf() < 0.6 else "tree-pine-small"
		var tr := _add_glb(prop, RU_GLB + t + ".glb", randf_range(1.5, 2.2), Vector3.ZERO, rng.randf() * TAU)
		if tr != null:
			Neon.tint_dark(tr, Color(1.35, 1.4, 1.55))
	elif kind < 0.72:
		_add_glb(prop, RU_GLB + "tree-park-large.glb", randf_range(1.3, 1.8), Vector3.ZERO, rng.randf() * TAU)
	else:
		_add_glb(prop, RU_GLB + "detail-bench.glb", randf_range(1.1, 1.5), Vector3.ZERO, rng.randf() * TAU)

func _prop_tokyo(prop: Node3D):
	var side: float = signf(prop.position.x)
	var kind: float = rng.randf()
	if kind < 0.5:
		var pole := _box(prop, Vector3(0.14, randf_range(2.6, 3.4), 0.14),
			_mat(Color(0.05, 0.0, 0.08), Color(1.0, 0.25, 0.95), 1.8), Vector3.ZERO)
		var sign := _add_glb(prop, CYBER_SIGN, 150.0,
			Vector3(0.0, randf_range(2.0, 2.6), 0.0), 0.0)
		if sign != null:
			sign.rotation.y = side * 0.5
	elif kind < 0.75:
		var d: String = "detail-parasol-" + ("a" if rng.randf() < 0.5 else "b")
		prop.position.x = side * randf_range(8.1, 8.6)
		var pl := _add_glb(prop, K_GLB + d + ".glb", randf_range(5.5, 7.0), Vector3.ZERO, rng.randf() * TAU)
		if pl != null:
			Neon.tint_dark(pl, Color(1.4, 0.9, 1.7))
	else:
		var col := _box(prop, Vector3(0.34, randf_range(2.4, 3.2), 0.34),
			_mat(Color(0.08, 0.0, 0.12), Color(0.95, 0.3, 1.0), 2.4), Vector3.ZERO)
		_box(prop, Vector3(0.55, 0.45, 0.55), mat_band, Vector3(0.0, randf_range(1.8, 2.4), 0.0))

func _prop_neon(prop: Node3D):
	var side: float = signf(prop.position.x)
	var kind: float = rng.randf()
	if kind < 0.4:
		var dvar: String = K_DETAIL[rng.randi_range(0, K_DETAIL.size() - 1)]
		prop.position.x = side * randf_range(9.4, 9.9)
		var det := _add_glb(prop, K_GLB + dvar + ".glb", randf_range(3.6, 4.8),
			Vector3(0.0, randf_range(2.4, 3.2), 0.0), side * 0.0)
		if det != null:
			Neon.tint_dark(det, _tint)
	elif kind < 0.7:
		var pole := _box(prop, Vector3(0.16, randf_range(2.2, 3.0), 0.16),
			_mat(Color(0.02, 0.02, 0.06), Color(0.0, 0.7, 1.0), 1.4), Vector3.ZERO)
		_box(prop, Vector3(1.0, 0.5, 0.16), mat_band,
			Vector3(0.0, randf_range(1.6, 2.4) + 0.25, 0.0))
	else:
		var pl := _add_glb(prop, K_GLB + "detail-parasol-a.glb", randf_range(5.5, 7.0),
			Vector3.ZERO, rng.randf() * TAU)
		if pl != null:
			Neon.tint_dark(pl, _tint)

func _process(delta):
	var dz: float = speed * delta

	for seg in _divider_dashes:
		seg.position.z += dz
		if seg.position.z > (DASH_COUNT * DASH_SPACING) / 2.0 + 6.0:
			seg.position.z -= DASH_COUNT * DASH_SPACING

	for b in _buildings_l:
		b.position.z += dz
		if b.position.z > BUILD_NEAR:
			_recycle_building(b)
	for b in _buildings_r:
		b.position.z += dz
		if b.position.z > BUILD_NEAR:
			_recycle_building(b)

	for p in _people:
		p.position.z += dz * 1.0
		p.rotation.y = sin(Time.get_ticks_msec() * 0.001 + p.position.x) * 0.04
		if p.position.z > 45.0:
			p.position.z -= BUILD_SPAN + 30.0

	for c in _cars:
		c.position.z += dz * 1.25
		var t: float = Time.get_ticks_msec() * 0.001
		var ph: float = c.get_meta("_ph")
		var bx: float = c.get_meta("_bx")
		var by: float = c.get_meta("_by")
		c.position.x = bx + sin(t * 1.3 + ph) * 0.18
		c.position.y = by + sin(t * 2.1 + ph) * 0.14
		c.rotation.y = sin(t * 1.1 + ph) * 0.35
		c.rotation.z = sin(t * 0.9 + ph) * 0.05
		var lamp: OmniLight3D = c.get_meta("_lamp")
		if lamp:
			lamp.light_energy = 1.5 + 0.6 * sin(t * 4.0 + ph)
		if c.position.z > 60.0:
			c.position.z = _car_slot(int(c.get_meta("slot")))
			var nx: float = rng.randf_range(-3.4, 3.4)
			c.set_meta("_bx", nx)
			c.position.x = nx
			_rebuild_vehicle(c)

	for a in _arches:
		a.position.z += dz
		if a.position.z > 45.0:
			a.position.z -= 7 * 19.0

	for p in _props:
		p.position.z += dz
		if p.position.z > 45.0:
			p.position.z = BUILD_FAR - randf_range(0.0, 8.0) + float(p.get_meta("_jz"))
			for ch in p.get_children():
				ch.free()
			_make_prop(p)

func set_speed(s: float):
	speed = s

func set_map(id: String):
	current_map = id
	_apply_theme()
	_build_materials()
	for b in _buildings_l:
		_install_building(b)
	for b in _buildings_r:
		_install_building(b)
	for c in _cars:
		_rebuild_vehicle(c)
	_rebuild_tron()
	_rebuild_snow()
	_build_arches()
	_build_props()

func _rebuild_tron():
	for w in _tron_walls:
		w.free()
	_tron_walls.clear()
	if not _use_tron:
		return
	var ps: PackedScene = load(TRON_PATH)
	if ps == null:
		return
	for side in [-1.0, 1.0]:
		var holder := Node3D.new()
		holder.position = Vector3(TRON_WALL_X * side, 0.0, 0.0)
		var wall := ps.instantiate()
		wall.scale = Vector3.ONE * 0.9
		holder.add_child(wall)
		add_child(holder)
		_tron_walls.append(holder)

func _rebuild_snow():
	if _snow_node != null:
		_snow_node.queue_free()
		_snow_node = null
	if not _use_snow:
		return
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 4.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3(0, -0.5, 0)
	pm.scale_min = 0.04
	pm.scale_max = 0.09
	pm.color = Color(1, 1, 1, 0.85)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(40, 24, 280)
	p.process_material = pm
	p.amount = 160
	p.lifetime = 9.0
	p.local_coords = false
	add_child(p)
	p.position = Vector3(0, 42, 10)
	_snow_node = p