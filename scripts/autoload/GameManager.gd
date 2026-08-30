extends Node
# ============================================================================
# GameManager (Autoload / Singleton)
# ----------------------------------------------------------------------------
# Controla el estado de LA PARTIDA ACTUAL ("el negocio"): dinero de la
# partida, día/pedido actual, energía actual, y qué frutas y armas se han
# desbloqueado/equipado SOLO durante este negocio (se reinician si el negocio
# quiebra). Para el progreso PERMANENTE (prestigio, reputación, desbloqueos
# históricos) revisa SaveManager.gd en su lugar.
#
# La ronda dura como máximo ROUND_TIME_SECONDS (límite FIJO, no mejorable): si
# se agota el tiempo, pasa lo mismo que si se agota la resistencia (se valida
# si se cumplió el objetivo). No existe mejora que lo modifique.
# Otros scripts escuchan las señales de aquí (money_changed, energy_changed,
# etc.) para actualizar la interfaz (HUD.gd) sin tener que consultar estas
# variables todo el tiempo.
# ============================================================================

signal money_changed(current_money: float)
signal order_progress_changed(progress: float, target: float)
signal order_completed(order_num: int)
signal energy_changed(current_energy: float, max_energy: float)
signal round_time_changed(time_left: float)
signal run_started
signal run_ended(summary: Dictionary)
signal fruit_destroyed_event(fruit_data: FruitData, reward: float, is_jackpot: bool)
signal run_knife_equipped(knife_id: String)

# Cuánto dinero hay que ganar para completar cada día/pedido (pedido 1, 2, 3...).
# Progresión geométrica COHERENTE con los premios de las frutas (~x1.75 por
# pedido): cada día es alcanzable con la fruta/arma del día anterior y deja
# un excedente para comprar mejoras en el mercado. Para pedidos más allá del
# último de la lista se usa una fórmula (ver get_order_target_for). Editar
# estos números cambia la dificultad temprana.
const ORDER_TARGETS: Array[float] = [
	30.0,        # Pedido 1
	52.0,        # Pedido 2
	92.0,        # Pedido 3
	160.0,       # Pedido 4
	280.0,       # Pedido 5
	490.0,       # Pedido 6
	860.0,       # Pedido 7
	1500.0,      # Pedido 8
	2625.0,      # Pedido 9
	4600.0,      # Pedido 10
	8050.0,      # Pedido 11
	14090.0,     # Pedido 12
	24660.0,     # Pedido 13
	43150.0,     # Pedido 14
	75520.0,     # Pedido 15
	132160.0,    # Pedido 16
	231280.0,    # Pedido 17
	404740.0,    # Pedido 18
	708300.0,    # Pedido 19
	1239500.0,   # Pedido 20
]

# Estados posibles de la partida: qué pantalla/momento del flujo estamos.
enum GameState {
	MENU,
	PLAYING,
	ORDER_CLEARED_CARD_SELECT,
	RUN_UPGRADES_OPEN,
	STATS_OPEN,
	RESULTS
}

var current_state: GameState = GameState.MENU

# --- Estado del negocio actual (se resetea en start_new_run) ---
var current_order: int = 1        # Pedido/día actual (1, 2, 3...)
var order_target: float = 100.0   # Dinero necesario para completar el pedido actual
var order_progress: float = 0.0   # Dinero ganado hasta ahora en este pedido
var run_money: float = 0.0        # Dinero disponible para gastar en la tienda (se resetea cada negocio)

var total_money_generated_run: float = 0.0
var total_fruits_cut_run: int = 0
var total_jackpots_run: int = 0

# Duración máxima de cada ronda en segundos. Es un límite FIJO: no depende de
# mejoras (no se puede mejorar), solo se rellena en start_new_run/advance_to_next_order.
const ROUND_TIME_SECONDS: float = 60.0

# Estado de la ronda actual: activa mientras se está jugando el día.
var is_round_active: bool = false
var current_energy: float = 100.0
var round_time_left: float = ROUND_TIME_SECONDS

func _process(delta: float) -> void:
	if not is_round_active or current_state != GameState.PLAYING:
		return
	round_time_left = maxf(0.0, round_time_left - delta)
	emit_signal("round_time_changed", round_time_left)
	if round_time_left <= 0.0:
		_end_round_and_validate()

# Fruits/knives bought during the current run only - reset on start_new_run(), like run upgrades and cards
var run_unlocked_fruits: Array[String] = ["strawberry"]
var run_unlocked_knives: Array[String] = ["weapon_fist"]
var run_equipped_knife: String = "weapon_fist"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func get_order_target_for(order_num: int) -> float:
	if order_num <= ORDER_TARGETS.size():
		return ORDER_TARGETS[order_num - 1] * StatsManager.get_order_target_multiplier()
	# Scaling formula for orders beyond 20
	return 1239500.0 * pow(1.75, order_num - 20) * StatsManager.get_order_target_multiplier()

# Empieza un negocio nuevo desde cero: reinicia dinero, pedido, energía y
# TAMBIÉN las frutas/armas desbloqueadas de la partida anterior (solo el
# progreso permanente en SaveManager sobrevive a esto).
func start_new_run() -> void:
	StatsManager.reset_run_stats()
	current_order = 1
	order_target = get_order_target_for(current_order)
	order_progress = 0.0
	run_money = 0.0
	total_money_generated_run = 0.0
	total_fruits_cut_run = 0
	total_jackpots_run = 0
	current_energy = StatsManager.get_final_max_energy()
	current_state = GameState.PLAYING
	run_unlocked_fruits = ["strawberry"]
	run_unlocked_knives = ["weapon_fist"]
	run_equipped_knife = "weapon_fist"
	emit_signal("run_knife_equipped", run_equipped_knife)
	SaveManager.record_day_started()
	
	round_time_left = ROUND_TIME_SECONDS
	emit_signal("round_time_changed", round_time_left)
	emit_signal("run_started")
	emit_signal("money_changed", run_money)
	emit_signal("order_progress_changed", order_progress, order_target)
	emit_signal("energy_changed", current_energy, StatsManager.get_final_max_energy())

	is_round_active = true

func pause_turn() -> void:
	is_round_active = false

func resume_turn() -> void:
	if current_state == GameState.PLAYING:
		is_round_active = true

func consume_energy(amount: float) -> bool:
	if current_energy < amount:
		current_energy = 0.0
		emit_signal("energy_changed", current_energy, StatsManager.get_final_max_energy())
		_end_round_and_validate()
		return false

	current_energy -= amount
	emit_signal("energy_changed", current_energy, StatsManager.get_final_max_energy())
	if current_energy <= 0.0:
		_end_round_and_validate()
	return true

# Penalización por golpear un obstáculo (piedra...): resta una fracción de la
# resistencia MÁXIMA. Devuelve cuánta resistencia se perdió realmente.
func penalize_resistance() -> float:
	var penalty: float = StatsManager.get_obstacle_resistance_penalty()
	var previous: float = current_energy
	current_energy = maxf(0.0, current_energy - penalty)
	emit_signal("energy_changed", current_energy, StatsManager.get_final_max_energy())
	if previous > 0.0 and current_energy <= 0.0:
		_end_round_and_validate()
	return previous - current_energy

# Se llama cada vez que un jugador corta una fruta con éxito. Calcula la
# recompensa final (aplicando el multiplicador de dinero) y actualiza el
# progreso del pedido y el dinero disponible en la tienda.
func register_fruit_cut(fruit_data: FruitData, base_reward: float, is_jackpot: bool) -> float:
	var final_reward: float = base_reward * StatsManager.get_final_money_multiplier()
	run_money += final_reward
	order_progress += final_reward
	total_money_generated_run += final_reward
	total_fruits_cut_run += 1
	if is_jackpot:
		total_jackpots_run += 1

	emit_signal("money_changed", run_money)
	emit_signal("order_progress_changed", order_progress, order_target)
	emit_signal("fruit_destroyed_event", fruit_data, final_reward, is_jackpot)

	return final_reward

func spend_run_money(amount: float) -> bool:
	if run_money >= amount:
		run_money -= amount
		emit_signal("money_changed", run_money)
		return true
	return false

# --- Frutas y armas desbloqueadas SOLO en este negocio ---
# (se pierden al quebrar; ver run_unlocked_fruits/run_unlocked_knives arriba)
func is_fruit_unlocked_this_run(fruit_id: String) -> bool:
	return fruit_id in run_unlocked_fruits

func unlock_fruit_this_run(fruit_id: String) -> void:
	if not (fruit_id in run_unlocked_fruits):
		run_unlocked_fruits.append(fruit_id)
		SaveManager.unlock_fruit(fruit_id) # keeps lifetime discovery record for Progress stats

func is_knife_unlocked_this_run(knife_id: String) -> bool:
	return knife_id in run_unlocked_knives

func unlock_knife_this_run(knife_id: String) -> void:
	if not (knife_id in run_unlocked_knives):
		run_unlocked_knives.append(knife_id)
		SaveManager.unlock_knife(knife_id) # keeps lifetime discovery record for Progress stats

func set_equipped_knife_this_run(knife_id: String) -> void:
	run_equipped_knife = knife_id
	emit_signal("run_knife_equipped", knife_id)

func _end_round_and_validate() -> void:
	is_round_active = false
	if order_progress >= order_target:
		# Objective met - round won, continue to comodines/shop
		current_state = GameState.ORDER_CLEARED_CARD_SELECT
		SoundManager.play_victory()
		emit_signal("order_completed", current_order)
	else:
		# Objective not met - round lost, business ends
		end_run_failed()

func advance_to_next_order() -> void:
	current_energy = StatsManager.get_final_max_energy()
	emit_signal("energy_changed", current_energy, StatsManager.get_final_max_energy())
	current_order += 1
	order_target = get_order_target_for(current_order)
	order_progress = 0.0
	current_state = GameState.PLAYING
	
	round_time_left = ROUND_TIME_SECONDS
	emit_signal("round_time_changed", round_time_left)
	emit_signal("order_progress_changed", order_progress, order_target)
	is_round_active = true

func end_run_failed() -> void:
	is_round_active = false
	current_state = GameState.RESULTS
	SoundManager.play_game_over()

	# Fórmula de Reputación: 10 puntos por cada pedido completado + 1 punto
	# por cada $50000 generados en total durante el negocio (dividido por una
	# cantidad alta para que el dinero aporte suplementos, no la mayor parte).
	var completed_orders_count: int = current_order - 1
	var prestige_from_orders: int = completed_orders_count * 10
	var prestige_from_money: int = int(floor(total_money_generated_run / 50000.0))
	var earned_prestige: int = prestige_from_orders + prestige_from_money

	SaveManager.add_prestige_points(earned_prestige)
	SaveManager.record_run_stats(completed_orders_count, total_money_generated_run, total_fruits_cut_run)

	var summary: Dictionary = {
		"completed_orders": completed_orders_count,
		"money_generated": total_money_generated_run,
		"fruits_cut": total_fruits_cut_run,
		"jackpots": total_jackpots_run,
		"best_order": current_order,
		"earned_prestige": earned_prestige,
		"total_prestige": SaveManager.get_prestige_points()
	}

	emit_signal("run_ended", summary)

func get_unlocked_fruits_for_current_order() -> Array[String]:
	var available: Array[String] = []
	for fruit_id in run_unlocked_fruits:
		available.append(str(fruit_id))
	return available
