extends Area2D
class_name Obstacle
# ============================================================================
# Obstacle: objeto que NO es una fruta (piedra...).
# ----------------------------------------------------------------------------
# No se destruye al cortarlo y no da recompensa: golpearlo penaliza la
# resistencia (ver GameManager.penalize_resistance). Tiene su propio cooldown
# de impacto para evitar penalizaciones dobles dentro de un mismo corte.
# Movimiento: usa el componente Ballistic (estilo Fruit Ninja).
# ============================================================================

@export var radius: float = 35.0

var hit_cooldown: float = 0.0
var spin_speed: float = 1.0
var _flash_tween: Tween

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ballistic: Ballistic = $Ballistic

func _ready() -> void:
	spin_speed = randf_range(-2.0, 2.0)

func setup(p_radius: float) -> void:
	radius = maxf(24.0, p_radius)
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = radius
	if collision_shape:
		collision_shape.shape = circle_shape
	queue_redraw()

func launch(from_position: Vector2, launch_velocity: Vector2, p_wall_left: float = Ballistic.DEFAULT_WALL_LEFT, p_wall_right: float = Ballistic.DEFAULT_WALL_RIGHT, p_escape_y: float = Ballistic.DEFAULT_ESCAPE_Y) -> void:
	if ballistic:
		# Gravedad y paredes compartidas con las frutas (ver Ballistic.<constantes>).
		ballistic.launch(from_position, launch_velocity, Ballistic.DEFAULT_GRAVITY, p_wall_left, p_wall_right, p_escape_y)

func _process(delta: float) -> void:
	if hit_cooldown > 0.0:
		hit_cooldown -= delta
	rotation += spin_speed * delta

func can_be_hit() -> bool:
	return hit_cooldown <= 0.0

func on_hit() -> void:
	hit_cooldown = 0.25
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_property(self, "scale", Vector2(1.3, 0.85), 0.06)
	_flash_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

# Rompe la piedra (tiró el comodín de probabilidad): la deja invisible y la
# libera. No penaliza ni rompe la racha; el llamador gestiona el feedback.
func break_stone() -> void:
	set_process(false)
	hide()
	collision_shape.set_deferred("disabled", true)
	queue_free()

func _draw() -> void:
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(-radius * 0.9, radius * 0.3),
		Vector2(-radius * 0.6, -radius * 0.7),
		Vector2(-radius * 0.1, -radius * 0.95),
		Vector2(radius * 0.5, -radius * 0.6),
		Vector2(radius * 0.95, 0.0),
		Vector2(radius * 0.6, radius * 0.8),
		Vector2(-radius * 0.2, radius * 0.9)
	])
	draw_colored_polygon(pts, Color(0.45, 0.47, 0.52))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.25, 0.27, 0.31), 3.0)
	draw_circle(Vector2(-radius * 0.25, -radius * 0.3), radius * 0.18, Color(0.62, 0.65, 0.7))

func _on_projectile_escaped() -> void:
	queue_free()
