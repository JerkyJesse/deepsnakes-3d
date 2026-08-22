extends Node

var _hiss: AudioStreamWAV
var _eat: AudioStreamWAV
var _die: AudioStreamWAV
var _click: AudioStreamWAV
var _strike: AudioStreamWAV
var _ambient: AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _amb_player: AudioStreamPlayer

func _ready() -> void:
	_hiss = _tone(140.0, 0.35, 0.18, true)
	_eat = _tone(420.0, 0.18, 0.28, false)
	_die = _tone(70.0, 0.55, 0.32, true)
	_click = _tone(880.0, 0.06, 0.2, false)
	_strike = _tone(190.0, 0.12, 0.3, true)
	_ambient = _tone(48.0, 2.4, 0.12, true)
	_ambient.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_ambient.loop_begin = 0
	_ambient.loop_end = int(_ambient.data.size() / 2)
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_amb_player = AudioStreamPlayer.new()
	_amb_player.bus = "Master"
	_amb_player.volume_db = -22.0
	add_child(_amb_player)

func start_ambient() -> void:
	_amb_player.stream = _ambient
	_amb_player.play()

func stop_ambient() -> void:
	_amb_player.stop()

func play_hiss() -> void:
	_play(_hiss, -8.0)

func play_eat() -> void:
	_play(_eat, -4.0)

func play_die() -> void:
	_play(_die, -2.0)

func play_click() -> void:
	_play(_click, -10.0)

func play_strike() -> void:
	_play(_strike, -6.0)

func _play(stream: AudioStreamWAV, db: float) -> void:
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = db
			p.play()
			return

func _tone(freq: float, duration: float, volume: float, noise: bool) -> AudioStreamWAV:
	var rate := 22050
	var n := int(duration * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(freq * 17.0)
	for i in n:
		var t := float(i) / float(rate)
		var env := 1.0 - t / duration
		var s: float
		if noise:
			s = (rng.randf() * 2.0 - 1.0) * 0.35 + sin(t * freq * TAU) * 0.65
		else:
			s = sin(t * freq * TAU)
		var v := int(clampf(s * volume * env, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 255
		data[i * 2 + 1] = (v >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream
