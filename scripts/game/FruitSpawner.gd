extends Node2D
class_name FruitSpawner
# ============================================================================
# FruitSpawner: lanza frutas (y obstáculos) desde la PARTE DE ABAJO siguiendo
# una trayectoria parabólica (estilo Fruit Ninja). La cantidad no es un número
# fijo en pantalla: se lanzan X proyectiles por segundo según
# StatsManager.get_final_launch_rate() (mejora "Cosecha Veloz" + prestigio
# "Ritmo Veloz" + comodines). Cada lanzamiento puede ser una fruta (de las
# desbloqueadas en este negocio) o un obstáculo (piedra) que penaliza la
# resistencia al golpearlo.
#
# La lógica de vida/resistencia/daño vive en Fruit.gd / Obstacle.gd; aquí solo
# se decide QUÉ se lanza y con qué velocidad.
# ============================================================================

const FRUIT_SCENE: PackedScene = preload("res://scenes/game/Fruit.tscn")
const OBSTACLE_SCENE: PackedScene = preload("res://scenes/game/Obstacle.tscn")

# Área de juego donde aparece la fruta (la altura de aparición queda justo
# debajo para que la parábola la suba hasta la pantalla).
@export var play_bounds: Rect2 = Rect2(10, 240, 700, 900)

# Parámetros del lanzamiento. La velocidad inicial (y el ángulo respecto a la
# vertical) se eligen al azar dentro de estos rangos para que cada lanzamiento
# sea un poco distinto y las parábolas llenen la pantalla (0..1280): los más
# bajos quedan a media altura y los más altos rozan el borde superior. La
# gravedad y el punto de desaparición viven en Ballistic.gd.
const LAUNCH_SPEED_MIN: float = 1350.0
const LAUNCH_SPEED_MAX: float = 1750.0
const LAUNCH_ANGLE_MAX_DEG: float = 20.0
# Altura de aparición: justo debajo del borde inferior de la pantalla.
const LAUNCH_Y: float = 1290.0

var active_fruits: Array[Fruit] = []
var active_obstacles: Array[Obstacle] = []
var is_spawning_enabled: bool = false
var launch_timer: float = 0.0

func _ready() -> void:
	GameManager.run_started.connect(func():
		clear_all()
		is_spawning_enabled = true
		launch_timer = 0.0
	)
	GameManager.run_ended.connect(func(_summary): clear_all(); is_spawning_enabled = false)
	GameManager.order_completed.connect(func(_order): clear_all())

func _process(delta: float) -> void:
	if not is_spawning_enabled or not GameManager.is_round_active:
		return
	_cleanup_stale()

	# Acumulador de frecuencia: por cada segundo completo con la frecuencia
	# actual se lanza un proyectil (frecuencia 1.0 = 1 fruta/seg).
	launch_timer += delta * StatsManager.get_final_launch_rate()
	var guard: int = 0
	while launch_timer >= 1.0 and guard < 8:
		launch_timer -= 1.0
		_launch_projectile()
		guard += 1

func _cleanup_stale() -> void:
	var i: int = active_fruits.size() - 1
	while i >= 0:
		if not is_instance_valid(active_fruits[i]):
			active_fruits.remove_at(i)
		i -= 1
	var j: int = active_obstacles.size() - 1
	while j >= 0:
		if not is_instance_valid(active_obstacles[j]):
			active_obstacles.remove_at(j)
		j -= 1

func enable_spawning() -> void:
	is_spawning_enabled = true
	launch_timer = 0.0

func disable_spawning() -> void:
	is_spawning_enabled = false

func clear_all() -> void:
	for fruit in active_fruits:
		if is_instance_valid(fruit):
			fruit.queue_free()
	active_fruits.clear()
	for obstacle in active_obstacles:
		if is_instance_valid(obstacle):
			obstacle.queue_free()
	active_obstacles.clear()

func _launch_projectile() -> void:
	if randf() < StatsManager.get_obstacle_chance():
		_launch_obstacle()
	else:
		_launch_fruit()

# Posición y velocidad inicial de cada lanzamiento: sale desde abajo del área
# de juego y sube con una parábola (la gravedad lo devuelve hacia abajo).
func _compute_launch() -> Dictionary:
	var speed: float = randf_range(LAUNCH_SPEED_MIN, LAUNCH_SPEED_MAX)
	var angle: float = deg_to_rad(randf_range(0.0, LAUNCH_ANGLE_MAX_DEG))
	var dir_x: float = 1.0 if randf() > 0.5 else -1.0
	var from: Vector2 = Vector2(
		randf_range(play_bounds.position.x + 70, play_bounds.end.x - 70),
		LAUNCH_Y
	)
	var vel: Vector2 = Vector2(sin(angle) * speed * dir_x, -cos(angle) * speed)
	return {"from": from, "vel": vel}

func _launch_fruit() -> void:
	var unlocked_ids: Array[String] = GameManager.get_unlocked_fruits_for_current_order()
	if unlocked_ids.is_empty():
		unlocked_ids = ["strawberry"]

	var chosen_id: String = unlocked_ids[randi() % unlocked_ids.size()]
	var fruit_res: FruitData = FruitDatabase.create_fruit_resource(chosen_id)
	var launch: Dictionary = _compute_launch()

	var fruit: Fruit = FRUIT_SCENE.instantiate()
	add_child(fruit)
	fruit.add_to_group("fruits")
	fruit.setup(fruit_res)
	fruit.launch(launch["from"], launch["vel"], play_bounds.position.x, play_bounds.end.x)
	fruit.fruit_destroyed.connect(_on_fruit_destroyed)
	active_fruits.append(fruit)

func _launch_obstacle() -> void:
	var launch: Dictionary = _compute_launch()
	var obstacle: Obstacle = OBSTACLE_SCENE.instantiate()
	add_child(obstacle)
	obstacle.add_to_group("obstacles")
	obstacle.setup(randf_range(30.0, 44.0))
	obstacle.launch(launch["from"], launch["vel"], play_bounds.position.x, play_bounds.end.x)
	active_obstacles.append(obstacle)

func _on_fruit_destroyed(fruit: Fruit) -> void:
	if fruit in active_fruits:
		active_fruits.erase(fruit)
