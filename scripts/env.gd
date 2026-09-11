extends WorldEnvironment

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
	env.ambient_light_energy = 1.5

	env.fog_enabled = false
	env.fog_light_color = Color(0.18, 0.08, 0.28)
	env.fog_density = 0.004
	env.fog_sky_affect = 0.5

	env.glow_enabled = true
	env.glow_intensity = 1.15
	env.glow_strength = 1.4
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.9

	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.2

	environment = env