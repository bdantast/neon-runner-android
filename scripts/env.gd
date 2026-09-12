extends WorldEnvironment

var _sky_mat: ProceduralSkyMaterial
var _env: Environment

func _ready():
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.0, 0.01, 0.035)
	sky_mat.sky_horizon_color = Color(0.38, 0.12, 0.6)
	sky_mat.ground_horizon_color = Color(0.2, 0.06, 0.34)
	sky_mat.ground_bottom_color = Color(0.0, 0.01, 0.035)
	sky_mat.sun_angle_max = 18.0
	sky_mat.energy_multiplier = 0.9
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_energy_multiplier = 1.0

	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.05

	env.fog_enabled = true
	env.fog_light_color = Color(0.12, 0.05, 0.2)
	env.fog_density = 0.006
	env.fog_sky_affect = 0.45

	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.25
	env.glow_bloom = 0.16
	env.glow_hdr_threshold = 1.0

	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.8

	environment = env
	_sky_mat = sky_mat
	_env = env

func apply_theme(id: String):
	if _env == null:
		return
	match id:
		"tokyo_neon":
			_sky_mat.sky_top_color = Color(0.02, 0.0, 0.05)
			_sky_mat.sky_horizon_color = Color(0.4, 0.1, 0.42)
			_sky_mat.ground_horizon_color = Color(0.16, 0.04, 0.22)
			_sky_mat.energy_multiplier = 1.0
			_env.ambient_light_energy = 1.2
			_env.glow_intensity = 0.95
			_env.glow_strength = 1.25
			_env.fog_light_color = Color(0.14, 0.03, 0.18)
		"moscow_frost":
			_sky_mat.sky_top_color = Color(0.01, 0.02, 0.06)
			_sky_mat.sky_horizon_color = Color(0.5, 0.6, 0.8)
			_sky_mat.ground_horizon_color = Color(0.2, 0.28, 0.42)
			_sky_mat.energy_multiplier = 1.0
			_env.ambient_light_energy = 1.25
			_env.glow_intensity = 0.9
			_env.glow_strength = 1.15
			_env.fog_light_color = Color(0.1, 0.16, 0.32)
		_:
			_sky_mat.sky_top_color = Color(0.0, 0.01, 0.035)
			_sky_mat.sky_horizon_color = Color(0.38, 0.12, 0.6)
			_sky_mat.ground_horizon_color = Color(0.2, 0.06, 0.34)
			_sky_mat.energy_multiplier = 0.9
			_env.ambient_light_energy = 1.1
			_env.glow_intensity = 0.9
			_env.glow_strength = 1.25
			_env.fog_light_color = Color(0.12, 0.05, 0.2)