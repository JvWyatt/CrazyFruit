extends Node
# ============================================================================
# SoundManager (Autoload / Singleton)
# ----------------------------------------------------------------------------
# Genera efectos de sonido por c\u00f3digo (sin archivos de audio) usando ondas
# simples (seno, ruido, sierra, cuadrada). No contiene valores de balance del
# juego; si quieres cambiar el sonido de una acci\u00f3n, busca la funci\u00f3n
# play_xxx() correspondiente m\u00e1s abajo en este archivo.
# ============================================================================

# Procedural Sound Effect Generator for instant audio feedback in Godot 4
var is_sound_enabled: bool = true

var player_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8

# Ruta opcional para pistas de música propias. Si el archivo NO existe, se
# genera un loop procedural (sin assets) para que los sliders de música del
# menú siempre tengan algo que controlar.
#   - MUSIC_PATH: música del MENÚ (relajada).
#   - GAME_MUSIC_PATH: música del JUEGO (más rítmica/activa).
const MUSIC_PATH: String = "res://assets/music/main_loop.ogg"
const GAME_MUSIC_PATH: String = "res://assets/music/game_loop.ogg"

var music_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	for i in range(POOL_SIZE):
		var asp := AudioStreamPlayer.new()
		asp.bus = "SFX"
		add_child(asp)
		player_pool.append(asp)
	play_menu_music()

func _get_available_player() -> AudioStreamPlayer:
	for player in player_pool:
		if not player.playing:
			return player
	return player_pool[0]

# Si por alguna razón el layout de buses no cargara (p.ej. una build sin el
# default_bus_layout.tres), crea el bus en runtime. Así los sliders del menú
# siempre tienen un bus real que controlar.
func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)

# ---------------------------------------------------------------------------
# Música (soundtrack)
# ---------------------------------------------------------------------------

# Contextos de música: "menu" (relajada) y "game" (más rítmica). Cada contexto
# tiene su propia pista: primero el archivo propio (assets/music/*.ogg) y, si
# no existe, un loop procedural generado en runtime.

var _menu_stream: AudioStream
var _game_stream: AudioStream
var _current_context: String = ""

func play_menu_music() -> void:
	_play_context("menu")

func play_game_music() -> void:
	_play_context("game")

func stop_music() -> void:
	if music_player != null:
		music_player.stop()
	_current_context = ""

func set_music_stream(stream: AudioStream) -> void:
	if music_player == null:
		return
	music_player.stream = stream
	if stream != null:
		music_player.play()

func _play_context(context: String) -> void:
	if music_player == null:
		return
	if _current_context == context and music_player.playing:
		return
	music_player.stream = _get_context_stream(context)
	_current_context = context
	music_player.play()

func _get_context_stream(context: String) -> AudioStream:
	match context:
		"menu":
			if _menu_stream == null:
				_menu_stream = _load_or_generate(MUSIC_PATH, Callable(self, "_generate_music_loop"))
			return _menu_stream
		"game":
			if _game_stream == null:
				_game_stream = _load_or_generate(GAME_MUSIC_PATH, Callable(self, "_generate_game_loop"))
			return _game_stream
	return _load_or_generate(MUSIC_PATH, Callable(self, "_generate_music_loop"))

func _load_or_generate(path: String, fallback: Callable) -> AudioStream:
	if ResourceLoader.exists(path):
		var custom_stream = load(path)
		if custom_stream is AudioStream:
			return custom_stream as AudioStream
	return fallback.call() as AudioStream

# Menú: loop ambiental lento (4 acordes de 2s, senos suaves + bajo).
func _generate_music_loop() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var chord_duration: float = 2.0
	var chords: Array = [
		[261.63, 329.63, 392.0],   # C4  E4  G4  (C mayor)
		[220.0, 261.63, 329.63],   # A3  C4  E4  (Am)
		[174.61, 220.0, 261.63],   # F3  A3  C4  (F mayor)
		[196.0, 246.94, 293.66],   # G3  B3  D4  (G mayor)
	]
	var fade: float = 0.35 # fade in/out por acorde para que los cortes no hagan "pops"
	var total: float = chord_duration * chords.size()
	var sample_count := int(sample_rate * total)
	var samples := PackedFloat32Array()
	samples.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / float(sample_rate)
		var chord_index := int(t / chord_duration) % chords.size()
		var local_t := fmod(t, chord_duration)
		var env := 1.0
		if local_t < fade:
			env = local_t / fade
		elif local_t > chord_duration - fade:
			env = (chord_duration - local_t) / fade

		var v := 0.0
		for f in chords[chord_index]:
			v += sin(TAU * float(f) * t) * 0.10
		v += sin(TAU * float(chords[chord_index][0]) * 0.5 * t) * 0.12

		samples[i] = v * env * 0.55
	return _pack_loop(samples, sample_rate)

# Juego: más rítmica y activa. Acordes de 1s (Am-F-C-G) con arpegio a la
# octava, bajo pulsante y una percusión definida: bombo con caída de tono
# (downbeat) + hat en downbeat y contratiempo, para que el corte tenga marcha.
func _generate_game_loop() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var chord_duration: float = 1.0
	var chords: Array = [
		[220.0, 261.63, 329.63, 440.0],   # Am
		[174.61, 220.0, 261.63, 349.23],  # F
		[261.63, 329.63, 392.0, 523.25],  # C
		[196.0, 246.94, 293.66, 392.0],   # G
	]
	var total: float = chord_duration * chords.size()
	var sample_count := int(sample_rate * total)
	var samples := PackedFloat32Array()
	samples.resize(sample_count)

	# Bombo: fase integrada con caída de 130Hz a 45Hz en ~120ms (sintesis basica
	# de kick). La fase se reinicia al empezar cada beat (0.5s).
	var kick_phase := 0.0
	var prev_beat := 0.5

	for i in range(sample_count):
		var t := float(i) / float(sample_rate)
		var chord_index := int(t / chord_duration) % chords.size()
		var lt := fmod(t, chord_duration)
		var beat := fmod(t, 0.5) # downbeat en beat=0, contratiempo en beat=0.25

		# Pequeño fade en los bordes del acorde para evitar clics.
		var env := 1.0
		if lt < 0.02:
			env = lt / 0.02
		elif lt > chord_duration - 0.02:
			env = (chord_duration - lt) / 0.02

		# Bombo (downbeat).
		if beat < prev_beat:
			kick_phase = 0.0
		prev_beat = beat
		var kick_freq := lerpf(130.0, 45.0, minf(beat / 0.12, 1.0))
		kick_phase += TAU * kick_freq / float(sample_rate)
		var kick := sin(kick_phase) * exp(-beat * 32.0) * 0.30

		# Hat cerrado: estallido de ruido corto en downbeat y contratiempo.
		var hat := 0.0
		if beat < 0.012:
			hat = randf_range(-1.0, 1.0) * 0.055 * (1.0 - beat / 0.012)
		elif beat >= 0.25 and beat < 0.262:
			hat = randf_range(-1.0, 1.0) * 0.045 * (1.0 - (beat - 0.25) / 0.012)

		var v := 0.0
		# Pad sostenido del acorde (más delgado que en el loop del menú).
		for f in chords[chord_index]:
			v += sin(TAU * float(f) * t) * 0.05
		# Arpegio: una nota del acorde a la octava por cada cuarto (0.25s).
		var note_index := int(lt / 0.25) % 4
		v += sin(TAU * float(chords[chord_index][note_index]) * 2.0 * t) * 0.07
		# Bajo pulsante en colcheas (decae rápido dentro de cada beat).
		v += sin(TAU * float(chords[chord_index][0]) * 0.5 * t) * 0.14 * exp(-beat * 18.0)
		# Percusión.
		v += kick + hat

		samples[i] = v * env * 0.62
	return _pack_loop(samples, sample_rate)

# Convierte muestras flotantes a un AudioStreamWAV mono de 16-bit con loop.
func _pack_loop(samples: PackedFloat32Array, sample_rate: int) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var int_val := int(clamp(samples[i] * 32767.0, -32768.0, 32767.0))
		var unsigned_val := int_val if int_val >= 0 else int_val + 65536
		bytes[i * 2] = unsigned_val & 0xFF
		bytes[i * 2 + 1] = (unsigned_val >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples.size()
	return stream

func _generate_tone_stream(freq_start: float, freq_end: float, duration: float, type: String = "sine", decay: float = 4.0) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_samples * 2) # 16-bit mono

	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var current_freq: float = lerp(freq_start, freq_end, t)
		phase += 2.0 * PI * current_freq / float(sample_rate)
		if phase > 2.0 * PI:
			phase -= 2.0 * PI

		var env: float = exp(-t * decay)
		var sample_val: float = 0.0

		match type:
			"sine":
				sample_val = sin(phase)
			"noise":
				sample_val = randf_range(-1.0, 1.0)
			"saw":
				sample_val = (fmod(phase, 2.0 * PI) / PI) - 1.0
			"square":
				sample_val = 1.0 if sin(phase) > 0.0 else -1.0

		var int_val: int = int(clamp(sample_val * env * 0.5 * 32767.0, -32768.0, 32767.0))
		# Store 16-bit LE
		var unsigned_val: int = int_val if int_val >= 0 else int_val + 65536
		byte_array[i * 2] = unsigned_val & 0xFF
		byte_array[i * 2 + 1] = (unsigned_val >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = byte_array
	return stream

func play_slice() -> void:
	if not is_sound_enabled: return
	var stream := _generate_tone_stream(randf_range(800.0, 1200.0), 300.0, 0.08, "noise", 8.0)
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -4.0
	p.play()

func play_hit() -> void:
	if not is_sound_enabled: return
	var stream := _generate_tone_stream(randf_range(400.0, 600.0), 180.0, 0.06, "saw", 10.0)
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -6.0
	p.play()

func play_thud() -> void:
	if not is_sound_enabled: return
	var stream := _generate_tone_stream(randf_range(120.0, 90.0), 60.0, 0.18, "noise", 9.0)
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -4.0
	p.play()

func play_coin() -> void:
	if not is_sound_enabled: return
	var stream := _generate_tone_stream(980.0, 1320.0, 0.12, "sine", 5.0)
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -5.0
	p.play()

func play_jackpot() -> void:
	if not is_sound_enabled: return
	var stream := _generate_tone_stream(500.0, 1600.0, 0.45, "square", 2.5)
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -2.0
	p.play()

func play_crit() -> void:
	if not is_sound_enabled: return
	var stream := _generate_tone_stream(1200.0, 600.0, 0.18, "saw", 6.0)
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -3.0
	p.play()

func play_click() -> void:
	if not is_sound_enabled: return
	var stream := _generate_tone_stream(700.0, 500.0, 0.04, "sine", 12.0)
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -8.0
	p.play()

func play_victory() -> void:
	if not is_sound_enabled: return
	var stream := _generate_tone_stream(600.0, 1200.0, 0.35, "sine", 3.0)
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -3.0
	p.play()

func play_game_over() -> void:
	if not is_sound_enabled: return
	var stream := _generate_tone_stream(500.0, 120.0, 0.6, "saw", 2.0)
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -2.0
	p.play()
