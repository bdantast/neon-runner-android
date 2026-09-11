extends Node

const SR := 44100

var _music: AudioStreamPlayer
var _collect: AudioStreamPlayer
var _hit: AudioStreamPlayer
var _music_cache := {}
var _active_music_theme := ""

func _ready():
	_music = AudioStreamPlayer.new()
	_music.volume_db = -14.0
	_music.stream = _music_stream("default")
	_music.finished.connect(_on_music_finished)
	add_child(_music)
	_collect = AudioStreamPlayer.new()
	_collect.volume_db = -32.0
	_collect.stream = _collect_stream()
	add_child(_collect)
	_hit = AudioStreamPlayer.new()
	_hit.volume_db = -5.0
	_hit.stream = _hit_stream()
	add_child(_hit)

func _theme_for_map(map_id: String) -> String:
	match map_id:
		"tokyo_neon":
			return "tokyo"
		"moscow_frost":
			return "moscow"
	return "default"

func play_music(map_id := ""):
	if _music == null:
		return
	var theme := _theme_for_map(map_id)
	if theme != _active_music_theme:
		_active_music_theme = theme
		if _music_cache.has(theme):
			_music.stream = _music_cache[theme]
		else:
			var s := _music_stream(theme)
			_music_cache[theme] = s
			_music.stream = s
	if not _music.playing:
		_music.play()

func _on_music_finished():
	if _music:
		_music.play()

func stop_music():
	if _music:
		_music.stop()

func play_collect():
	if _collect and not _collect.playing:
		_collect.play()

func play_hit():
	if _hit:
		_hit.play()

func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var n: int = samples.size()
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var v: float = clampf(samples[i], -1.0, 1.0)
		var sv: int = int(roundf(v * 32767.0))
		data.encode_s16(i * 2, sv)
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = SR
	s.stereo = false
	s.data = data
	return s

func _music_stream(theme: String) -> AudioStream:
	if theme != "default":
		for ext in [".ogg", ".wav", ".mp3"]:
			var p: String = "res://assets/audio/music_" + theme + ext
			if FileAccess.file_exists(p):
				return load(p)
	if theme == "default":
		if FileAccess.file_exists("res://assets/audio/music.ogg"):
			return load("res://assets/audio/music.ogg")
		if FileAccess.file_exists("res://assets/audio/music.wav"):
			return load("res://assets/audio/music.wav")
		if FileAccess.file_exists("res://assets/audio/music.mp3"):
			return load("res://assets/audio/music.mp3")
		var dir := DirAccess.open("res://assets/audio")
		if dir:
			dir.list_dir_begin()
			var f := dir.get_next()
			while f != "":
				if f.ends_with(".ogg") or f.ends_with(".wav") or f.ends_with(".mp3"):
					if f.find("music_") != 0:
						return load("res://assets/audio/" + f)
				f = dir.get_next()
	return _synth(theme)

func _synth(theme: String) -> AudioStream:
	var qlen := 0.77
	var flavor := "neon"
	var chords: Array = [
		[43.65, 87.31, 174.61, 261.63, 329.63],
		[49.0, 98.0, 196.0, 246.94, 293.66],
		[43.65, 87.31, 174.61, 220.0, 261.63],
		[32.7, 65.41, 130.81, 196.0, 261.63],
	]
	match theme:
		"tokyo":
			qlen = 0.42
			flavor = "tokyo"
			chords = [
				[220.0, 246.94, 329.63, 440.0],
				[196.0, 220.0, 293.66, 392.0],
				[164.81, 196.0, 246.94, 329.63],
				[220.0, 261.63, 329.63, 440.0],
			]
		"moscow":
			qlen = 1.05
			flavor = "moscow"
			chords = [
				[110.0, 130.81, 164.81, 220.0, 261.63],
				[98.0, 116.54, 146.83, 196.0, 246.94],
				[110.0, 130.81, 155.56, 220.0, 233.08],
				[87.31, 103.83, 130.81, 174.61, 207.65],
			]
	var bars := 4.0
	var n := int(SR * bars * 4.0 * qlen)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2087
	for i in range(n):
		var t: float = float(i) / float(SR)
		var q: int = int(t / qlen)
		var bar: int = int(t / (4.0 * qlen)) % 4
		var chord: Array = chords[bar]
		var qt: float = t - float(q) * qlen
		var inbar: int = q % 4
		var acc := 0.0
		if flavor == "tokyo":
			if qt < 0.05:
				var ke: float = exp(-qt * 40.0)
				acc += sin(TAU * (220.0 - 40.0 * (qt / 0.05)) * t) * ke * 0.16
			var eighth: int = (q * 2) % 8
			var sub: float = fmod(qt, qlen * 0.5)
			var ev: float = exp(-sub * 14.0)
			var deg: int = eighth % 4
			var pluck_f: float = chord[deg % chord.size()] * 2.0
			if eighth % 2 == 1:
				pluck_f = chord[3 % chord.size()] * 2.0
			acc += (sin(TAU * pluck_f * t) + 0.35 * sin(TAU * pluck_f * 2.01 * t)) * ev * 0.11
			var pad_env: float = sin(PI * clampf((qt + 0.05) * 1.1, 0.0, 1.0))
			for k in range(1, chord.size()):
				var f: float = chord[k]
				acc += (sin(TAU * f * t) + sin(TAU * f * 1.003 * t + 0.7)) * pad_env * 0.022
		elif flavor == "moscow":
			var pad_env: float = sin(PI * clampf((qt + 0.12) * 0.85, 0.0, 1.0))
			pad_env = pow(pad_env, 1.7)
			var trem: float = 0.92 + 0.08 * sin(TAU * 0.35 * t)
			for k in range(1, chord.size()):
				var f: float = chord[k]
				acc += (sin(TAU * f * t) + sin(TAU * (f * 0.998) * t + 1.1)) * pad_env * trem * 0.045
			acc += sin(TAU * chord[0] * 0.5 * t) * pad_env * 0.04
			if inbar % 2 == 0 and qt > qlen * 0.3 and qt < qlen * 0.3 + 0.5:
				var bt: float = qt - qlen * 0.3
				var be: float = exp(-bt * 9.0)
				acc += sin(TAU * (chord[0] * 0.5) * t) * be * 0.12
			if inbar % 2 == 1:
				var rall := (inbar + (bar * 2)) % 3
				if rall != 2:
					var bl: float = exp(-(qt - 0.1) * 30.0) if qt > 0.1 else 0.0
					acc += sin(TAU * chord[chord.size() - 1] * 2.0 * t) * bl * 0.05
		else:
			if qt < 0.18:
				var ke: float = exp(-qt * 24.0)
				acc += sin(TAU * (38.0 - 12.0 * (qt / 0.18)) * t) * ke * 0.12
			if inbar == 0 or inbar == 2:
				var be: float = 1.0 - exp(-qt * 6.0)
				be *= exp(-qt * 2.4)
				acc += sin(TAU * chord[0] * 2.0 * t) * be * 0.1
			var pad_env2: float = sin(PI * clampf((qt + 0.1) * 1.35, 0.0, 1.0))
			pad_env2 = pow(pad_env2, 1.4)
			var trem2: float = 0.94 + 0.06 * sin(TAU * 0.8 * t)
			for k in range(1, chord.size()):
				var f: float = chord[k]
				acc += (sin(TAU * f * t) + sin(TAU * (f * 1.004) * t + 0.5)) * pad_env2 * trem2 * 0.03
				acc += sin(TAU * (f * 3.0) * t) * pad_env2 * 0.008
			if inbar % 2 == 1 and qt > qlen * 0.5 and qt < qlen * 0.5 + 0.12:
				var ae: float = exp(-(qt - qlen * 0.5) * 34.0)
				acc += (sin(TAU * chord[4] * 2.0 * t) + 0.4 * sin(TAU * chord[4] * 3.0 * t + 0.3)) * ae * 0.05
		out[i] = acc
	var peak := 0.0
	for v in out:
		peak = maxf(peak, absf(v))
	if peak > 0.001:
		for i in range(n):
			out[i] *= 0.6 / peak
	var s := _wav(out)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = int(n)
	return s

func _collect_stream() -> AudioStream:
	if FileAccess.file_exists("res://assets/audio/collect.wav"):
		return load("res://assets/audio/collect.wav")
	if FileAccess.file_exists("res://assets/audio/collect.ogg"):
		return load("res://assets/audio/collect.ogg")
	var dur := 0.3
	var n := int(SR * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SR)
		var f: float = 660.0 + 1100.0 * (t / dur)
		var env: float = exp(-t * 10.0)
		var s := sin(TAU * f * t) * env * 0.22
		s += sin(TAU * f * 1.5 * t) * env * 0.1
		s += sin(TAU * f * 2.0 * t) * env * 0.06
		if t > 0.12 and i % 3 == 0:
			s += sin(TAU * 1568.0 * (t - 0.12)) * exp(-(t - 0.12) * 26.0) * 0.075
		out[i] = s
	return _wav(out)

func _hit_stream() -> AudioStream:
	if FileAccess.file_exists("res://assets/audio/hit.wav"):
		return load("res://assets/audio/hit.wav")
	if FileAccess.file_exists("res://assets/audio/hit.ogg"):
		return load("res://assets/audio/hit.ogg")
	var dur := 0.55
	var n := int(SR * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2087
	for i in range(n):
		var t: float = float(i) / float(SR)
		var thump: float = sin(TAU * (130.0 - 95.0 * t / dur) * t) * exp(-t * 7.0) * 0.55
		var noise: float = (rng.randf() * 2.0 - 1.0) * exp(-t * 16.0) * 0.4
		out[i] = thump + noise
	return _wav(out)