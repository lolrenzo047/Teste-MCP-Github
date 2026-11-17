extends Area3D
## Bola: quica nas paredes superior/inferior e nos bastões.
## O ângulo de saída depende de onde a bola toca o bastão.

signal paddle_hit
signal wall_hit

@export var radius := 0.25
@export var arena_half_height := 4.5
@export var start_speed := 8.0
@export var max_speed := 18.0
@export var speed_gain := 1.05
@export var max_bounce_angle_deg := 55.0

var velocity := Vector3.ZERO
var speed := 0.0
var active := false


func _ready() -> void:
	add_to_group("ball")


func reset_ball() -> void:
	active = false
	velocity = Vector3.ZERO
	global_position = Vector3.ZERO


func stop() -> void:
	active = false
	velocity = Vector3.ZERO


func launch(direction_x: float) -> void:
	speed = start_speed
	var angle := deg_to_rad(randf_range(-25.0, 25.0))
	velocity = Vector3(signf(direction_x) * cos(angle), sin(angle), 0.0) * speed
	active = true


func _physics_process(delta: float) -> void:
	if not active:
		return
	global_position += velocity * delta
	rotate_z(-velocity.x * delta * 0.5)

	if global_position.y + radius > arena_half_height and velocity.y > 0.0:
		global_position.y = arena_half_height - radius
		velocity.y = -velocity.y
		wall_hit.emit()
	elif global_position.y - radius < -arena_half_height and velocity.y < 0.0:
		global_position.y = -arena_half_height + radius
		velocity.y = -velocity.y
		wall_hit.emit()

	for paddle in get_tree().get_nodes_in_group("paddles"):
		_check_paddle(paddle)


func _check_paddle(paddle: Node3D) -> void:
	var half: Vector2 = paddle.get_half_size()
	var offset := global_position - paddle.global_position
	if absf(offset.x) > half.x + radius or absf(offset.y) > half.y + radius:
		return
	# só rebate se a bola estiver indo em direção ao bastão
	if signf(velocity.x) != signf(paddle.global_position.x):
		return

	var contact := clampf(offset.y / (half.y + radius * 0.5), -1.0, 1.0)
	speed = minf(speed * speed_gain, max_speed)
	var angle := contact * deg_to_rad(max_bounce_angle_deg)
	var dir_x := -signf(paddle.global_position.x)
	velocity = Vector3(dir_x * cos(angle), sin(angle), 0.0) * speed
	global_position.x = paddle.global_position.x + dir_x * (half.x + radius)
	paddle_hit.emit()
