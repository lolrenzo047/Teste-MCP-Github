extends AudioStreamPlayer
## Música aconchegante em Dó maior (loop de 8 compassos, 76 BPM).
## Melodia e progressão compostas/validadas no Music21 (Cmaj7-Am7-Fmaj7-G6 / Fmaj7-Em7-Dm7-G7)
## e sintetizadas aqui em tempo de execução (caixinha de música + piano suave + pad).

const BPM := 76.0
const SR := 22050
const BEATS := 32.0

# Acordes por compasso (notas MIDI: baixo + vozes)
const CHORDS := [
	[48, 52, 55, 59], # Cmaj7
	[45, 48, 52, 55], # Am7
	[41, 45, 48, 52], # Fmaj7
	[43, 47, 50, 52], # G6
	[41, 45, 48, 52], # Fmaj7
	[40, 43, 47, 50], # Em7
	[38, 41, 45, 48], # Dm7
	[43, 47, 50, 53], # G7
]
const ARP := [0, 1, 2, 3, 2, 1, 2, 1]

# [nota MIDI, início em tempos, duração em tempos]
const MELODY := [
	[76, 0.0, 1.5], [79, 1.5, 0.5], [76, 2.0, 1.0], [74, 3.0, 1.0],
	[72, 4.0, 2.0], [76, 6.0, 1.0], [74, 7.0, 1.0],
	[69, 8.0, 1.5], [72, 9.5, 0.5], [76, 10.0, 2.0],
	[74, 12.0, 1.0], [76, 13.0, 1.0], [74, 14.0, 2.0],
	[72, 16.0, 1.5], [69, 17.5, 0.5], [72, 18.0, 1.0], [76, 19.0, 1.0],
	[79, 20.0, 2.0], [76, 22.0, 1.0], [74, 23.0, 1.0],
	[77, 24.0, 1.5], [76, 25.5, 0.5], [74, 26.0, 1.0], [72, 27.0, 1.0],
	[71, 28.0, 1.5], [74, 29.5, 0.5], [72, 30.0, 2.0],
]

var _thread: Thread
var _stream: AudioStreamWAV

func _ready() -> void:
	volume_db = -9.0
	_thread = Thread.new()
	_thread.start(_build)

func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()

func _finish() -> void:
	_thread.wait_to_finish()
	stream = _stream
	play()

func _build() -> void:
	var spb := 60.0 / BPM
	var total := int(BEATS * spb * SR)
	var buf := PackedFloat32Array()
	buf.resize(total)

	for bar in range(8):
		var ch: Array = CHORDS[bar]
		var t0 := bar * 4.0
		# Pad suave (vozes 2 e 3) e baixo
		_add_pad(buf, ch[1], t0, 4.0, 0.045)
		_add_pad(buf, ch[2], t0, 4.0, 0.04)
		_add_note(buf, ch[0], t0, 3.5, 0.16, 1.1, 0.0)
		# Arpejo em colcheias
		for i in range(8):
			var n: int = ch[ARP[i]] + 12
			_add_note(buf, n, t0 + i * 0.5, 0.5, 0.07, 3.2, 0.0)
	# Melodia (caixinha de música / sino suave)
	for m in MELODY:
		_add_note(buf, m[0], m[1], m[2], 0.2, 1.7, 1.0)

	var peak := 0.001
	for i in range(total):
		peak = maxf(peak, absf(buf[i]))
	var gain := 0.8 / peak
	var bytes := PackedByteArray()
	bytes.resize(total * 2)
	for i in range(total):
		bytes.encode_s16(i * 2, int(clampf(buf[i] * gain, -1.0, 1.0) * 32767.0))

	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = bytes
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = total
	_stream = w
	call_deferred("_finish")

func _freq(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)

func _add_note(buf: PackedFloat32Array, midi: int, start_beat: float, dur_beats: float,
		amp: float, decay: float, bell: float) -> void:
	var spb := 60.0 / BPM
	var total := buf.size()
	var f := _freq(midi)
	var w := TAU * f
	var ring := dur_beats * spb + 0.9
	var n := int(ring * SR)
	var start := int(start_beat * spb * SR)
	for i in range(n):
		var t := float(i) / SR
		var v := sin(w * t) + 0.22 * sin(2.0 * w * t) * exp(-t * 3.0) + 0.07 * sin(3.0 * w * t) * exp(-t * 5.0)
		if bell > 0.0:
			v += 0.12 * bell * sin(4.0 * w * t) * exp(-t * 6.0)
		var env := (1.0 - exp(-t * 180.0)) * exp(-t * decay)
		var tail := ring - t
		if tail < 0.05:
			env *= tail / 0.05
		buf[(start + i) % total] += v * env * amp

func _add_pad(buf: PackedFloat32Array, midi: int, start_beat: float, dur_beats: float, amp: float) -> void:
	var spb := 60.0 / BPM
	var total := buf.size()
	var w := TAU * _freq(midi)
	var len_s := dur_beats * spb
	var n := int(len_s * SR)
	var start := int(start_beat * spb * SR)
	for i in range(n):
		var t := float(i) / SR
		var env := pow(sin(PI * t / len_s), 1.5)
		var v := sin(w * t) + 0.3 * sin(w * 1.003 * t + 1.0)
		buf[(start + i) % total] += v * env * amp
