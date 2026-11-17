extends Node3D
## Controla um bastão (raquete): move apenas na vertical, dentro da arena.

@export var is_left := true
@export var speed := 9.0
@export var arena_half_height := 4.5
## Metade da largura/altura da área de colisão (x = espessura, y = comprimento).
@export var half_size := Vector2(0.22, 1.1)
@export var sway_degrees := 18.0

var _up_action := "p1_up"
var _down_action := "p1_down"
var _time := 0.0

@onready var model: Node3D = $Model


func _ready() -> void:
	add_to_group("paddles")
	if not is_left:
		_up_action = "p2_up"
		_down_action = "p2_down"
		_time = PI


func get_half_size() -> Vector2:
	return half_size


func reset() -> void:
	position.y = 0.0


func _process(delta: float) -> void:
	var direction := Input.get_axis(_down_action, _up_action)
	var limit := arena_half_height - half_size.y
	position.y = clampf(position.y + direction * speed * delta, -limit, limit)
	_time += delta
	if model:
		model.rotation.y = sin(_time * 1.5) * deg_to_rad(sway_degrees)
