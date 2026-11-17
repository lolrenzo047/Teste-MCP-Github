extends Area3D
## Zona de gol: avisa quando a bola entra no lado esquerdo ou direito.

signal ball_entered(goal_side: String)

@export_enum("left", "right") var side: String = "left"


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("ball"):
		ball_entered.emit(side)
