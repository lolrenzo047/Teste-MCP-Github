extends Node
## Guarda a pontuação e informa quando alguém atinge a pontuação alvo.

signal score_changed(left: int, right: int)

@export var target_score := 11

var left_score := 0
var right_score := 0


func reset() -> void:
	left_score = 0
	right_score = 0
	score_changed.emit(left_score, right_score)


func add_point(side: String) -> void:
	if side == "left":
		left_score += 1
	else:
		right_score += 1
	score_changed.emit(left_score, right_score)


func get_winner() -> String:
	if left_score >= target_score:
		return "left"
	if right_score >= target_score:
		return "right"
	return ""
