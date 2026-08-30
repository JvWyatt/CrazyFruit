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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var asp := AudioStreamPlayer.new()
		asp.bus = "Master"
		add_child(asp)
		player_pool.append(asp)

func _get_available_player() -> AudioStreamPlayer:
	for player in player_pool:
		if not player.playing:
			return player
	return player_pool[0]

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
