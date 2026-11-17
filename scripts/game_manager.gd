extends Node3D
## Controla o fluxo da partida: menu, saque, jogo e fim de partida.

enum State { MENU, SERVE, PLAYING, GAME_OVER }

@export var winning_score := 11

var state: State = State.MENU
var _sfx := {}

@onready var ball = $Ball
@onready var score_manager = $ScoreManager
@onready var ui = $UIManager
@onready var goal_left = $Arena/GoalLeft
@onready var goal_right = $Arena/GoalRight
@onready var paddle_left = $PaddleLeft
@onready var paddle_right = $PaddleRight


func _ready() -> void:
	randomize()
	_build_audio()
	score_manager.target_score = winning_score
	score_manager.score_changed.connect(ui.set_scores)
	goal_left.ball_entered.connect(_on_goal)
	goal_right.ball_entered.connect(_on_goal)
	ball.paddle_hit.connect(_play.bind("paddle"))
	ball.wall_hit.connect(_play.bind("wall"))
	score_manager.reset()
	ball.reset_ball()
	ui.show_message("PONG 3D\nPressione ESPAÇO para iniciar")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_match") and (state == State.MENU or state == State.GAME_OVER):
		_start_match()


func _start_match() -> void:
	score_manager.reset()
	paddle_left.reset()
	paddle_right.reset()
	ui.hide_message()
	ball.visible = true
	_serve(1.0 if randf() > 0.5 else -1.0, 0.0)


func _serve(direction_x: float, pause_before: float) -> void:
	state = State.SERVE
	if pause_before > 0.0:
		await get_tree().create_timer(pause_before).timeout
	if state != State.SERVE:
		return
	ball.reset_ball()
	await get_tree().create_timer(1.0).timeout
	if state != State.SERVE:
		return
	ball.launch(direction_x)
	state = State.PLAYING


func _on_goal(goal_side: String) -> void:
	if state != State.PLAYING:
		return
	ball.stop()
	_play("score")
	var scorer := "right" if goal_side == "left" else "left"
	score_manager.add_point(scorer)
	var winner: String = score_manager.get_winner()
	if winner != "":
		_end_match(winner)
	else:
		# saca em direção a quem sofreu o ponto
		_serve(-1.0 if goal_side == "left" else 1.0, 0.7)


func _end_match(winner: String) -> void:
	state = State.GAME_OVER
	_play("win")
	var name_text := "Jogador 1" if winner == "left" else "Jogador 2"
	ui.show_message("%s venceu!\nPressione ESPAÇO para jogar de novo" % name_text)


# ---- áudio gerado por código (sem arquivos externos) ----

func _build_audio() -> void:
	var defs := {
		"paddle": _make_tone(560.0, 0.08, 0.4, 0.0),
		"wall": _make_tone(280.0, 0.07, 0.4, 0.0),
		"score": _make_tone(220.0, 0.35, 0.5, -120.0),
		"win": _make_tone(440.0, 0.7, 0.45, 520.0),
	}
	for key in defs:
		var player := AudioStreamPlayer.new()
		player.stream = defs[key]
		add_child(player)
		_sfx[key] = player


func _play(key: String) -> void:
	if _sfx.has(key):
		_sfx[key].play()


func _make_tone(freq: float, duration: float, volume: float, slide: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / rate
		var phase := TAU * (freq * t + 0.5 * slide * t * t)
		var wave := 0.5 * signf(sin(phase)) + 0.5 * sin(phase)
		var envelope := 1.0 - float(i) / count
		var value := int(clampf(wave * envelope * volume, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream
