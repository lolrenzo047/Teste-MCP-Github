extends CanvasLayer
## Placar, mensagens centrais e dica de controles.

@onready var score_left: Label = $ScoreLeft
@onready var score_right: Label = $ScoreRight
@onready var message: Label = $Message


func set_scores(left: int, right: int) -> void:
	score_left.text = str(left)
	score_right.text = str(right)


func show_message(text: String) -> void:
	message.text = text
	message.visible = true


func hide_message() -> void:
	message.visible = false
