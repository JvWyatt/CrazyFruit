extends Node
# ============================================================================
# StatsManager (Autoload / Singleton)
# ----------------------------------------------------------------------------
# Aquí viven casi TODOS los números de balance del juego:
#   - Catálogo de cuchillos (daño, gasto de energía, precio)
#   - Mejoras compradas durante la partida ("Mejoras" del mercado)
#   - Bonos temporales de comodines (cartas) conseguidos en la partida
#   - Mejoras permanentes de prestigio (compradas con reputación)
#   - Las fórmulas "get_final_...()" combinan todo lo anterior para dar el
#     valor final que usa el resto del juego (daño real, energía real, etc).
#
# Si quieres cambiar el balance del juego, este es uno de los archivos
# principales a editar (junto con FruitDatabase.gd para las frutas).
# ============================================================================

signal stats_updated

# Base normal = 1.0: el "energy_cost" de cada arma (tabla de abajo) YA es el
# gasto real de resistencia por golpe. Se deja como constante para ajustar
# todo el gasto de un plumazo si hiciera falta (ej. puño 1.0 = 1 energía/golpe).
const RESISTANCE_COST_MULTIPLIER: float = 1.0
# Probabilidad base (0.0 a 1.0) de que aparezca una fruta dorada al generarse.
# 0%: la Fruta Dorada SOLO se activa mediante comodines (card_golden_fruit_chance).
const GOLDEN_FRUIT_CHANCE: float = 0.0
# Multiplicador aplicado a las recompensas mínima/máxima de las frutas para
# ajustar el balance general de ganancias sin tocar cada fruta una por una.
const REWARD_REBALANCE_MULTIPLIER: float = 1
# Daño crítico: SIEMPRE multiplica el daño por 1.5. No se puede mejorar ni por
# mejoras del mercado ni por comodines (balance fijo).
const CRITICAL_DAMAGE_MULTIPLIER: float = 1.5

# ----------------------------------------------------------------------------
# FRECUENCIA DE LANZAMIENTO (frutas/obstáculos por segundo)
# ----------------------------------------------------------------------------
# En lugar de un número fijo de frutas simultáneas en pantalla, el juego lanza
# proyectiles desde abajo a razón de X por segundo (estilo Fruit Ninja). La
# frecuencia final = base x (1 + bonus run) x (1 + bonus prestigio) x comodines.
const BASE_LAUNCH_RATE: float = 1.0
# +10% de frecuencia por cada compra de la mejora "Cosecha Veloz" del mercado.
const RUN_LAUNCH_BONUS_PER_LEVEL: float = 0.10
# +25% de frecuencia por cada nivel de prestigio "Ritmo Veloz".
const PRESTIGE_LAUNCH_BONUS_PER_LEVEL: float = 0.25

# ----------------------------------------------------------------------------
# OBSTÁCULOS (piedras...) - estilo Fruit Ninja
# ----------------------------------------------------------------------------
# Frecuencia de obstáculos COMPLETAMENTE SEPARADA de la frecuencia de frutas:
# es una TASA FIJA de piedras por segundo, NO depende de la mejora/prestigio/
# comodines de "frecuencia de lanzamiento" y NO es mejorable de ningún modo.
# Se lanzan con un intervalo ALEATORIO entre 1 y 2 segundos para que no sean
# predecibles.
const OBSTACLE_INTERVAL_MIN: float = 1.0
const OBSTACLE_INTERVAL_MAX: float = 2.0
# Fracción de la resistencia MÁXIMA total que se pierde al golpear un
# obstáculo (10% por golpe: un peligro moderado y sostenido).
const OBSTACLE_RESISTANCE_PENALTY_FRACTION: float = 0.10

# ----------------------------------------------------------------------------
# TABLA DE ARMAS (CUCHILLOS)
# ----------------------------------------------------------------------------
# Cada arma tiene: damage (daño por golpe), energy_cost (gasto de resistencia
# ANTES de aplicar RESISTANCE_COST_MULTIPLIER) y price (costo para desbloquear
# durante la partida, ver RunUpgradeModal.gd). Edita estos números para
# balancear cada arma.
var knives_db: Dictionary = {
	"weapon_fist": {
		"id": "weapon_fist",
		"name": "Puño",
		"description": "La herramienta más básica para empezar.",
		"damage": 5.0,
		"energy_cost": 1,
		"price": 0,
		"icon": "👊"
	},
	"weapon_fork": {
		"id": "weapon_fork", "name": "Tenedor", "description": "Un pequeño avance en precisión.",
		"damage": 10.0, "energy_cost": 0.9, "price": 100, "icon": "🍴"
	},
	"weapon_table_knife": {
		"id": "weapon_table_knife", "name": "Cuchillo de mesa", "description": "Un filo sencillo y práctico.",
		"damage": 15.0, "energy_cost": 0.8, "price": 550, "icon": "🔪"
	},
	"weapon_scissors": {
		"id": "weapon_scissors", "name": "Tijera", "description": "Dos filos para cortes más rápidos.",
		"damage": 20.0, "energy_cost": 0.7, "price": 3025, "icon": "✂️"
	},
	"weapon_box_cutter": {
		"id": "weapon_box_cutter", "name": "Cúter", "description": "Una hoja fina y sorprendentemente eficaz.",
		"damage": 25.0, "energy_cost": 0.6, "price": 16638, "icon": "🪒"
	},
	"weapon_knife": {
		"id": "weapon_knife", "name": "Cuchillo", "description": "Un filo fiable para el trabajo diario.",
		"damage": 35.0, "energy_cost": 0.5, "price": 91506, "icon": "🔪"
	},
	"weapon_machete": {
		"id": "weapon_machete", "name": "Machete", "description": "Fuerza y alcance en cada golpe.",
		"damage": 50.0, "energy_cost": 0.4, "price": 503284, "icon": "🗡️"
	},
	"weapon_axe": {
		"id": "weapon_axe", "name": "Hacha", "description": "Un corte pesado que parte cualquier fruta.",
		"damage": 70.0, "energy_cost": 0.3, "price": 2767063, "icon": "🪓"
	},
	"weapon_sword": {
		"id": "weapon_sword", "name": "Espada", "description": "Precisión y potencia de nivel superior.",
		"damage": 95.0, "energy_cost": 0.2, "price": 15218847, "icon": "⚔️"
	},
	"weapon_chainsaw": {
		"id": "weapon_chainsaw", "name": "Motosierra", "description": "La herramienta definitiva para cortar sin parar.",
		"damage": 130.0, "energy_cost": 0.1, "price": 83703658, "icon": "🪚"
	}
}

# ----------------------------------------------------------------------------
# MEJORAS DEL MERCADO ("Mejoras" tab del RunUpgradeModal)
# ----------------------------------------------------------------------------
# Se compran con el dinero de la partida (run_money) y se PIERDEN al quebrar
# el negocio (ver StatsManager.reset_run_stats() y GameManager.start_new_run()).
# run_upgrade_levels guarda cuántas veces se compró cada mejora en esta partida.
var run_upgrade_levels: Dictionary = {
	"damage": 0,       # +5% damage
	"energy_max": 0,   # +5% max resistance
	"luck": 0,         # +0.5% grand sale chance
	"money": 0,        # +5% money
	"launch_rate": 0   # +10% launch frequency
}

# Definición de cada mejora: nombre, descripción, costo inicial (base_cost) y
# cuánto sube el precio cada vez que se compra (cost_mult, ej. 1.1x = +10%).
# Son ACUMULATIVAS e infinitas: cada compra sube el nivel y el precio crece con
# la fórmula (base_cost × cost_mult^nivel), sin tabla de valores fija.
# Los base_cost están a la escala de lo que se gana por pedido: permiten
# algunas compras los primeros días pero no llenar la tienda de golpe.
# Balance: daño/resistencia/ganancias del mercado y de prestigio doblados
# (mercado: 5% -> 10%; prestigio: 10% -> 20%), jackpot con su categoría propia
# (+0.5% mercado / +1% prestigio, sin cambios), y frecuencia de frutas sin
# cambios (mercado +10% / prestigio +25%).
var run_upgrade_definitions: Dictionary = {
	"damage": {"name": "Afilado de Hoja", "desc": "+10% daño", "base_cost": 5, "cost_mult": 1.5, "icon": "💥"},
	"energy_max": {"name": "Resistencia", "desc": "+10% resistencia máxima", "base_cost": 5, "cost_mult": 1.5, "icon": "⚡"},
	"luck": {"name": "Golpe de Suerte", "desc": "+0.777% probabilidad de Jackpot", "base_cost": 5, "cost_mult": 1.5, "icon": "🍀"},
	"money": {"name": "Negociación", "desc": "+10% multiplicador de ganancias", "base_cost": 5, "cost_mult": 1.5, "icon": "💰"},
	"launch_rate": {"name": "Cosecha Veloz", "desc": "+10% frecuencia de lanzamiento", "base_cost": 5, "cost_mult": 1.5, "icon": "🚀"}
}

# ----------------------------------------------------------------------------
# BONOS DE COMODINES (CARTAS) - también se resetean cada partida
# ----------------------------------------------------------------------------
# Cada vez que el jugador elige un comodín (CardSelectionModal), se llama a
# apply_card_upgrade() que suma su efecto a una de estas variables. Los
# multiplicadores empiezan en 1.0 (sin efecto) y los bonos aditivos en 0.0.
var card_damage_multiplier: float = 1.0
var card_energy_multiplier: float = 1.0
var card_money_multiplier: float = 1.0
var card_jackpot_bonus: float = 0.0
var card_jackpot_multiplier_bonus: float = 0.0
var card_crit_chance: float = 0.0
var card_launch_rate_multiplier: float = 1.0
var card_reward_min_multiplier: float = 1.0
var card_reward_max_multiplier: float = 1.0
var card_fruit_hp_multiplier: float = 1.0
var card_energy_cost_multiplier: float = 1.0
var card_weapon_price_multiplier: float = 1.0
var card_fruit_price_multiplier: float = 1.0
var card_upgrade_price_multiplier: float = 1.0
var card_order_target_multiplier: float = 1.0
var card_golden_fruit_chance: float = 0.0
# Bonus ADITIVO al multiplicador de racha (se suma al que dé la racha actual).
# Cada comodín de racha suma su valor (Común +0.1, Rara +0.2, Épica +0.5, Legendaria +1.0).
var card_streak_bonus: float = 0.0
# Probabilidad adicional (sumada, 0.0 a 1.0) de ROMPER una piedra al golpearla
# (desaparece, no penaliza). Épica +0.01 / Legendaria +0.03.
var card_stone_break_chance: float = 0.0
# Contador de comodines "primera piedra del día no quita resistencia" (Rara).
var card_first_stone_free: int = 0
# Contador de comodines míticos "mantener la racha entre días".
var card_streak_keep: int = 0
# Bonus ADITIVO de puntos de prestigio por día completado (se suma al punto
# base de 1 ⭐). Es la ÚNICA forma de aumentar la reputación diaria: solo los
# comodines ACTIVOS pueden aportar aquí (0.0 si ninguno tiene este efecto).
var card_prestige_bonus: float = 0.0
var active_cards: Array = []

# --- Caché de stats FINALES (hot paths) --------------------------------------
# Se recalculan SOLO cuando cambian sus entradas, para que los getters que se
# llaman todos los frames (lanzamiento de frutas) o ante cada corte (daño,
# energía, dinero, jackpot) sean O(1). Un valor guardado como -1 marca "sucio":
# se recalcula a petición la próxima vez que se lea. Cualquier operación que
# cambie mejoras del mercado, comodines, prestigio O el arma equipada debe
# llamar a invalidar_stat_cache() antes de emitir stats_updated (ver
# buy_run_upgrade, apply_card_upgrade, buy_prestige_upgrade, reset_run_stats,
# SaveManager.reset_save y GameManager.set_equipped_knife_this_run).
var _final_damage: float = -1.0
var _final_max_energy: float = -1.0
var _final_energy_cost: float = -1.0
var _final_money_multiplier: float = -1.0
var _final_jackpot_bonus: float = -1.0
var _final_launch_rate: float = -1.0

# Marca TODOS los valores finales como "sucios": se recalcularán en el próximo
# acceso a cada getter. Llamar SIEMPRE tras cualquier cambio de sus entradas.
func invalidate_stat_cache() -> void:
	_final_damage = -1.0
	_final_max_energy = -1.0
	_final_energy_cost = -1.0
	_final_money_multiplier = -1.0
	_final_jackpot_bonus = -1.0
	_final_launch_rate = -1.0

func _ready() -> void:
	reset_run_stats()

# Se llama al empezar cada negocio nuevo (ver GameManager.start_new_run()).
# Vuelve las mejoras y los bonos de comodines a su estado inicial, tal como
# se espera en un roguelite: solo lo permanente (prestigio) sobrevive.
func reset_run_stats() -> void:
	invalidate_stat_cache()
	for key in run_upgrade_levels.keys():
		run_upgrade_levels[key] = 0
	card_damage_multiplier = 1.0
	card_energy_multiplier = 1.0
	card_money_multiplier = 1.0
	card_jackpot_bonus = 0.0
	card_jackpot_multiplier_bonus = 0.0
	card_crit_chance = 0.0
	card_launch_rate_multiplier = 1.0
	card_reward_min_multiplier = 1.0
	card_reward_max_multiplier = 1.0
	card_fruit_hp_multiplier = 1.0
	card_energy_cost_multiplier = 1.0
	card_weapon_price_multiplier = 1.0
	card_fruit_price_multiplier = 1.0
	card_upgrade_price_multiplier = 1.0
	card_order_target_multiplier = 1.0
	card_golden_fruit_chance = 0.0
	card_streak_bonus = 0.0
	card_stone_break_chance = 0.0
	card_first_stone_free = 0
	card_streak_keep = 0
	card_prestige_bonus = 0.0
	active_cards.clear()
	emit_signal("stats_updated")

func get_equipped_knife_data() -> Dictionary:
	var equipped_id: String = GameManager.run_equipped_knife
	if knives_db.has(equipped_id):
		return knives_db[equipped_id]
	return knives_db["weapon_fist"]

# Daño final de un golpe = daño base del arma equipada
#   x multiplicador de comodines
#   x (1 + 20% por cada nivel de prestigio "experience")
# Para la mejora "Afilado de Hoja": mientras el daño esté por debajo de 20,
# cada nivel suma +1 de daño (piso mínimo); al llegar a 20 o más se estabiliza
# en el +10% por nivel. El valor devuelto siempre se entrega con un decimal.
func get_final_damage() -> float:
	if _final_damage < 0.0:
		_final_damage = _compute_final_damage()
	return _final_damage

# Ver get_final_damage: el cálculo real del daño final (solo se ejecuta cuando
# el valor está marcado como sucio).
func _compute_final_damage() -> float:
	var knife: Dictionary = get_equipped_knife_data()
	var base_dmg: float = float(knife.get("damage", 10.0))
	var level: int = run_upgrade_levels["damage"]
	var prestige_bonus: float = 1.0 + (SaveManager.get_prestige_level("experience") * 0.20)
	# Daño sin el bono de la mejora del mercado (base x comodines x prestigio).
	var base_final: float = base_dmg * card_damage_multiplier * prestige_bonus
	if base_final < 20.0 and level > 0:
		return snappedf(base_final + (level * 1.0), 0.1)
	return snappedf(base_dmg * (1.0 + (level * 0.10)) * card_damage_multiplier * prestige_bonus, 0.1)

# Resistencia máxima final = 100 base x mejoras del mercado x comodines x prestigio
func get_final_max_energy() -> float:
	if _final_max_energy < 0.0:
		_final_max_energy = _compute_final_max_energy()
	return _final_max_energy

func _compute_final_max_energy() -> float:
	var base_energy: float = 100.0
	var run_bonus: float = 1.0 + (run_upgrade_levels["energy_max"] * 0.10)
	var prestige_bonus: float = 1.0 + (SaveManager.get_prestige_level("expert_hand") * 0.20)
	return base_energy * run_bonus * card_energy_multiplier * prestige_bonus

# Cuánta resistencia se gasta por cada golpe con el arma equipada (ver
# RESISTANCE_COST_MULTIPLIER arriba para el significado del multiplicador).
func get_final_energy_cost() -> float:
	if _final_energy_cost < 0.0:
		_final_energy_cost = _compute_final_energy_cost()
	return _final_energy_cost

func _compute_final_energy_cost() -> float:
	var knife: Dictionary = get_equipped_knife_data()
	return float(knife.get("energy_cost", 5.0)) * RESISTANCE_COST_MULTIPLIER * card_energy_cost_multiplier

# Multiplicador final aplicado al dinero ganado por cada fruta cortada.
func get_final_money_multiplier() -> float:
	if _final_money_multiplier < 0.0:
		_final_money_multiplier = _compute_final_money_multiplier()
	return _final_money_multiplier

func _compute_final_money_multiplier() -> float:
	var run_bonus: float = 1.0 + (run_upgrade_levels["money"] * 0.10)
	var prestige_bonus: float = 1.0 + (SaveManager.get_prestige_level("good_provider") * 0.20)
	return 1.0 * run_bonus * card_money_multiplier * prestige_bonus

# Probabilidad extra (sumada, no multiplicada) de que una fruta sea "Gran Venta"/Jackpot.
func get_final_jackpot_bonus() -> float:
	if _final_jackpot_bonus < 0.0:
		_final_jackpot_bonus = _compute_final_jackpot_bonus()
	return _final_jackpot_bonus

func _compute_final_jackpot_bonus() -> float:
	var run_bonus: float = run_upgrade_levels["luck"] * 0.00777
	var prestige_bonus: float = SaveManager.get_prestige_level("good_fortune") * 0.0777
	return run_bonus + card_jackpot_bonus + prestige_bonus

func get_final_jackpot_multiplier() -> float:
	return 2.0 + card_jackpot_multiplier_bonus

func get_golden_fruit_chance() -> float:
	return GOLDEN_FRUIT_CHANCE + card_golden_fruit_chance

# Bonus ADITIVO acumulado por comodines de racha (p.ej. +0.5 con un Épico).
func get_streak_bonus() -> float:
	return card_streak_bonus

# Probabilidad total (0.0 a 1.0) de romper una piedra al golpearla.
func get_stone_break_chance() -> float:
	return card_stone_break_chance

# Bonus de puntos de prestigio (reputación) por día completado: se suma al
# punto base de 1 ⭐. Solo los comodines ACTIVOS pueden aumentarlo (ver
# card_prestige_bonus / effect_type "prestige" en _apply_card_effect).
func get_prestige_per_day_bonus() -> float:
	return card_prestige_bonus

# True si el jugador tiene al menos un comodín "primera piedra del día gratis".
func has_first_stone_free() -> bool:
	return card_first_stone_free > 0

# True si el jugador tiene al menos un comodín mítico que mantiene la racha
# entre días.
func has_streak_keep() -> bool:
	return card_streak_keep > 0

func get_fruit_max_hp_multiplier() -> float:
	return card_fruit_hp_multiplier

func get_fruit_min_reward_multiplier() -> float:
	return card_reward_min_multiplier * REWARD_REBALANCE_MULTIPLIER

func get_fruit_max_reward_multiplier() -> float:
	return card_reward_max_multiplier * REWARD_REBALANCE_MULTIPLIER

func get_weapon_price(price: int) -> int:
	return int(round(price * card_weapon_price_multiplier))

func get_fruit_price(price: int) -> int:
	return int(round(price * card_fruit_price_multiplier))

func get_final_critical_chance() -> float:
	return card_crit_chance

# El multiplicador crítico es FIJO (x2). Los comodines solo pueden aumentar la
# probabilidad de crítico (card_crit_chance), nunca el daño.
func get_final_critical_multiplier() -> float:
	return CRITICAL_DAMAGE_MULTIPLIER

# Frutas (o obstáculos) lanzadas por segundo.
func get_final_launch_rate() -> float:
	if _final_launch_rate < 0.0:
		_final_launch_rate = _compute_final_launch_rate()
	return _final_launch_rate

func _compute_final_launch_rate() -> float:
	var run_bonus: float = 1.0 + (run_upgrade_levels["launch_rate"] * RUN_LAUNCH_BONUS_PER_LEVEL)
	var prestige_bonus: float = 1.0 + (SaveManager.get_prestige_level("launch_speed") * PRESTIGE_LAUNCH_BONUS_PER_LEVEL)
	return BASE_LAUNCH_RATE * run_bonus * card_launch_rate_multiplier * prestige_bonus

# Intervalo ALEATORIO (en segundos) entre obstáculos: 1 a 2 s. Independiente
# de la frecuencia de frutas y de todas las mejoras/comodines/prestigio.
func get_obstacle_interval() -> float:
	return randf_range(OBSTACLE_INTERVAL_MIN, OBSTACLE_INTERVAL_MAX)

# Penalización de resistencia por golpear un obstáculo (fracción de la máxima).
func get_obstacle_resistance_penalty() -> float:
	return maxf(1.0, get_final_max_energy() * OBSTACLE_RESISTANCE_PENALTY_FRACTION)

# Precio final de las mejoras del mercado: la primera compra (nivel 0) cuesta
# el base_cost ($5) y cada compra siguiente crece ×1.5: 5, 7.5, 11.25 → ..., y
# así sucesivamente (fórmula base_cost × cost_mult^nivel, sin tabla fija).
func get_run_upgrade_cost(upgrade_id: String) -> float:
	if not run_upgrade_definitions.has(upgrade_id):
		return 999999.0
	var def: Dictionary = run_upgrade_definitions[upgrade_id]
	var level: int = run_upgrade_levels[upgrade_id]
	return snappedf(float(def["base_cost"]) * pow(float(def["cost_mult"]), float(level)) * card_upgrade_price_multiplier, 0.01)

func get_order_target_multiplier() -> float:
	return card_order_target_multiplier

func buy_run_upgrade(upgrade_id: String) -> void:
	if run_upgrade_levels.has(upgrade_id):
		run_upgrade_levels[upgrade_id] += 1
		GameManager._upgrades_bought_this_run += 1
		AchievementManager.record_metric("upgrades_bought_run", 1)
		if upgrade_id == "launch_rate" and run_upgrade_levels["launch_rate"] >= 3:
			AchievementManager.set_metric("launch_upgrades_run", 3)
		if run_upgrade_levels["damage"] >= 1 and run_upgrade_levels["energy_max"] >= 1 and run_upgrade_levels["luck"] >= 1 and run_upgrade_levels["money"] >= 1:
			AchievementManager.set_flag("bought_all_upgrade_types")
		invalidate_stat_cache()
		emit_signal("stats_updated")

func apply_card_upgrade(card_id: String, effect_type: String, effect_value: Variant, card_title: String = "") -> void:
	active_cards.append({"id": card_id, "title": card_title})
	SaveManager.discover_card(card_id)
	# Logros de comodines descubiertos.
	var rarity: String = "Común"
	for card in CardDatabase.ALL_CARDS:
		if str(card["id"]) == str(card_id):
			rarity = str(card["rarity"])
			break
	var discovered_count: int = SaveManager.get_discovered_cards().size()
	AchievementManager.set_metric("cards_discovered", discovered_count)
	match rarity:
		"Rara":
			AchievementManager.record_metric("cards_rare", 1)
		"Épica":
			AchievementManager.record_metric("cards_epic", 1)
		"Legendaria":
			AchievementManager.record_metric("cards_legendary", 1)
		"Mítico":
			AchievementManager.set_flag("discover_mythic")
	if effect_type == "multi":
		for effect in effect_value:
			_apply_card_effect(str(effect["type"]), float(effect["value"]))
	else:
		_apply_card_effect(effect_type, float(effect_value))
	invalidate_stat_cache()
	emit_signal("stats_updated")

func _apply_card_effect(effect_type: String, effect_value: float) -> void:
	match effect_type:
		"damage":
			card_damage_multiplier += effect_value
		"energy_max":
			card_energy_multiplier += effect_value
		"money":
			card_money_multiplier += effect_value
		"jackpot":
			card_jackpot_bonus += effect_value
		"jackpot_multiplier":
			card_jackpot_multiplier_bonus += effect_value
		"crit_chance":
			card_crit_chance += effect_value
		"launch_rate":
			card_launch_rate_multiplier += effect_value
		"reward_min":
			card_reward_min_multiplier += effect_value
		"reward_max":
			card_reward_max_multiplier += effect_value
		"fruit_hp":
			card_fruit_hp_multiplier += effect_value
		"energy_cost":
			card_energy_cost_multiplier += effect_value
		"weapon_price":
			card_weapon_price_multiplier += effect_value
		"fruit_price":
			card_fruit_price_multiplier += effect_value
		"upgrade_price":
			card_upgrade_price_multiplier += effect_value
		"order_target":
			card_order_target_multiplier += effect_value
		"golden_fruit_chance":
			card_golden_fruit_chance += effect_value
		"all_prices":
			card_weapon_price_multiplier += effect_value
			card_fruit_price_multiplier += effect_value
			card_upgrade_price_multiplier += effect_value
		"streak_bonus":
			card_streak_bonus += effect_value
		"stone_break_chance":
			card_stone_break_chance += effect_value
		"prestige":
			card_prestige_bonus += effect_value
		"first_stone_free":
			card_first_stone_free += int(effect_value)
		"streak_keep":
			card_streak_keep += int(effect_value)

# ----------------------------------------------------------------------------
# MEJORAS DE PRESTIGIO (permanentes, compradas con reputación/estrellas)
# ----------------------------------------------------------------------------
# Se guardan en SaveManager (prestige_levels) y NO se resetean nunca. Son
# ACUMULATIVAS e infinitas (no tienen max_level): cada compra sube el nivel y
# el efecto crece con él. Se generan puntos de reputación por cada día
# completado (ver GameManager): 1 ⭐ base por día + bonus de comodines ACTIVOS.
# Los precios por nivel usan los costes base de la tabla (3 para la mayoría,
# 5 para las fuertes) y crecen ×1.5 por nivel: 3 → 4.5 → 6.75 → ... y
# 5 → 7.5 → 11.25 → ...
var prestige_definitions: Dictionary = {
	"experience": {
		"name": "Maestría",
		"desc": "+20% Daño inicial",
		"cost": 3,
		"icon": "⚔️"
	},
	"expert_hand": {
		"name": "Experiencia",
		"desc": "+20% Resistencia Máxima",
		"cost": 3,
		"icon": "🧤"
	},
	"good_provider": {
		"name": "Buen Proveedor",
		"desc": "+20% Multiplicador de Ganancias",
		"cost": 3,
		"icon": "📦"
	},
	"good_fortune": {
		"name": "Buena Fortuna",
		"desc": "+7.77% Probabilidad de Jackpot",
		"cost": 5,
		"icon": "⭐"
	},
	"launch_speed": {
		"name": "Ritmo Veloz",
		"desc": "+25% Frecuencia de Lanzamiento",
		"cost": 5,
		"icon": "🚀"
	},
}

# Factor de crecimiento del precio de prestigio por nivel adquirido (×1.5).
const PRESTIGE_PRICE_GROWTH: float = 1.5

func get_prestige_upgrade_cost(upgrade_id: String) -> float:
	if not prestige_definitions.has(upgrade_id):
		return 999999.0
	var def: Dictionary = prestige_definitions[upgrade_id]
	var current_lvl: int = SaveManager.get_prestige_level(upgrade_id)
	# Los valores no se hardcodean por nivel: el precio crece con la fórmula.
	return snappedf(float(def.get("cost", 1)) * pow(PRESTIGE_PRICE_GROWTH, current_lvl), 0.01)

func is_prestige_upgrade_maxed(upgrade_id: String) -> bool:
	return not prestige_definitions.has(upgrade_id)

func buy_prestige_upgrade(upgrade_id: String) -> bool:
	if is_prestige_upgrade_maxed(upgrade_id):
		return false
	var cost: float = get_prestige_upgrade_cost(upgrade_id)
	if SaveManager.spend_prestige_points(cost):
		var new_lvl: int = SaveManager.get_prestige_level(upgrade_id) + 1
		SaveManager.set_prestige_level(upgrade_id, new_lvl)
		AchievementManager.record_metric("prestige_spent", cost)
		AchievementManager.record_metric("prestige_bought", 1)
		invalidate_stat_cache()
		emit_signal("stats_updated")
		return true
	return false
