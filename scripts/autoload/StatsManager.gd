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
# 1% base para que el mecánico de Fruta Dorada se vea sin depender de las
# cartas; los comodines de "Fruta Dorada" suman encima (ver card_golden_fruit_chance).
const GOLDEN_FRUIT_CHANCE: float = 0.01
# Multiplicador aplicado a las recompensas mínima/máxima de las frutas para
# ajustar el balance general de ganancias sin tocar cada fruta una por una.
const REWARD_REBALANCE_MULTIPLIER: float = 1
# Daño crítico: SIEMPRE multiplica el daño por 2. No se puede mejorar ni por
# mejoras del mercado ni por comodines (balance fijo).
const CRITICAL_DAMAGE_MULTIPLIER: float = 2.0

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
# Probabilidad de que un lanzamiento sea un obstáculo en vez de una fruta.
const BASE_OBSTACLE_CHANCE: float = 0.08
const OBSTACLE_CHANCE_PER_ORDER: float = 0.004
const MAX_OBSTACLE_CHANCE: float = 0.30
# Fracción de la resistencia MÁXIMA total que se pierde al golpear un
# obstáculo (25% por golpe: las piedras son peligros y juntar 4 casi acaba la
# ronda).
const OBSTACLE_RESISTANCE_PENALTY_FRACTION: float = 0.25

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
		"damage": 3.0,
		"energy_cost": 1,
		"price": 0,
		"icon": "👊"
	},
	"weapon_fork": {
		"id": "weapon_fork", "name": "Tenedor", "description": "Un pequeño avance en precisión.",
		"damage": 6.0, "energy_cost": 0.9, "price": 25, "icon": "🍴"
	},
	"weapon_table_knife": {
		"id": "weapon_table_knife", "name": "Cuchillo de mesa", "description": "Un filo sencillo y práctico.",
		"damage": 10.0, "energy_cost": 0.8, "price": 45, "icon": "🔪"
	},
	"weapon_scissors": {
		"id": "weapon_scissors", "name": "Tijera", "description": "Dos filos para cortes más rápidos.",
		"damage": 16.0, "energy_cost": 0.7, "price": 80, "icon": "✂️"
	},
	"weapon_box_cutter": {
		"id": "weapon_box_cutter", "name": "Cúter", "description": "Una hoja fina y sorprendentemente eficaz.",
		"damage": 24.0, "energy_cost": 0.6, "price": 150, "icon": "🪒"
	},
	"weapon_knife": {
		"id": "weapon_knife", "name": "Cuchillo", "description": "Un filo fiable para el trabajo diario.",
		"damage": 35.0, "energy_cost": 0.5, "price": 270, "icon": "🔪"
	},
	"weapon_machete": {
		"id": "weapon_machete", "name": "Machete", "description": "Fuerza y alcance en cada golpe.",
		"damage": 50.0, "energy_cost": 0.4, "price": 500, "icon": "🗡️"
	},
	"weapon_axe": {
		"id": "weapon_axe", "name": "Hacha", "description": "Un corte pesado que parte cualquier fruta.",
		"damage": 70.0, "energy_cost": 0.3, "price": 900, "icon": "🪓"
	},
	"weapon_sword": {
		"id": "weapon_sword", "name": "Espada", "description": "Precisión y potencia de nivel superior.",
		"damage": 95.0, "energy_cost": 0.2, "price": 1600, "icon": "⚔️"
	},
	"weapon_chainsaw": {
		"id": "weapon_chainsaw", "name": "Motosierra", "description": "La herramienta definitiva para cortar sin parar.",
		"damage": 130.0, "energy_cost": 0.1, "price": 2900, "icon": "🪚"
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
	"luck": 0,         # +0.1% grand sale chance
	"money": 0,        # +5% money
	"launch_rate": 0   # +10% launch frequency
}

# Definición de cada mejora: nombre, descripción, costo inicial (base_cost) y
# cuánto sube el precio cada vez que se compra (cost_mult, ej. 1.35 = +35%).
# Los base_cost están a la escala de lo que se gana por pedido (decenas):
# permiten 1-2 compras los primeros días pero NO llenar la tienda de golpe.
var run_upgrade_definitions: Dictionary = {
	"damage": {"name": "Afilado de Hoja", "desc": "+10% daño", "base_cost": 10, "cost_mult": 1.35, "icon": "💥"},
	"energy_max": {"name": "Resistencia", "desc": "+10% resistencia máxima", "base_cost": 15, "cost_mult": 1.35, "icon": "⚡"},
	"luck": {"name": "Golpe de Suerte", "desc": "+0.3% probabilidad de Jackpot", "base_cost": 30, "cost_mult": 1.45, "icon": "🍀"},
	"money": {"name": "Negociación", "desc": "+10% multiplicador de ganancias", "base_cost": 40, "cost_mult": 1.45, "icon": "💰"},
	"launch_rate": {"name": "Cosecha Veloz", "desc": "+10% frecuencia de lanzamiento", "base_cost": 20, "cost_mult": 1.40, "icon": "🚀"}
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
var active_cards: Array = []

func _ready() -> void:
	reset_run_stats()

# Se llama al empezar cada negocio nuevo (ver GameManager.start_new_run()).
# Vuelve las mejoras y los bonos de comodines a su estado inicial, tal como
# se espera en un roguelite: solo lo permanente (prestigio) sobrevive.
func reset_run_stats() -> void:
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
	active_cards.clear()
	emit_signal("stats_updated")

func get_equipped_knife_data() -> Dictionary:
	var equipped_id: String = GameManager.run_equipped_knife
	if knives_db.has(equipped_id):
		return knives_db[equipped_id]
	return knives_db["weapon_fist"]

# Daño final de un golpe = daño base del arma equipada
#   x (1 + 10% por cada nivel de la mejora "damage" del mercado)
#   x multiplicador de comodines
#   x (1 + 20% por cada nivel de prestigio "experience")
func get_final_damage() -> float:
	var knife: Dictionary = get_equipped_knife_data()
	var base_dmg: float = float(knife.get("damage", 10.0))
	var run_bonus: float = 1.0 + (run_upgrade_levels["damage"] * 0.10)
	var prestige_bonus: float = 1.0 + (SaveManager.get_prestige_level("experience") * 0.20)
	return base_dmg * run_bonus * card_damage_multiplier * prestige_bonus

# Resistencia máxima final = 100 base x mejoras del mercado x comodines x prestigio
func get_final_max_energy() -> float:
	var base_energy: float = 100.0
	var run_bonus: float = 1.0 + (run_upgrade_levels["energy_max"] * 0.10)
	var prestige_bonus: float = 1.0 + (SaveManager.get_prestige_level("expert_hand") * 0.20)
	return base_energy * run_bonus * card_energy_multiplier * prestige_bonus

# Cuánta resistencia se gasta por cada golpe con el arma equipada (ver
# RESISTANCE_COST_MULTIPLIER arriba para el significado del multiplicador).
func get_final_energy_cost() -> float:
	var knife: Dictionary = get_equipped_knife_data()
	return float(knife.get("energy_cost", 5.0)) * RESISTANCE_COST_MULTIPLIER * card_energy_cost_multiplier

# Multiplicador final aplicado al dinero ganado por cada fruta cortada.
func get_final_money_multiplier() -> float:
	var run_bonus: float = 1.0 + (run_upgrade_levels["money"] * 0.10)
	var prestige_bonus: float = 1.0 + (SaveManager.get_prestige_level("good_provider") * 0.20)
	return 1.0 * run_bonus * card_money_multiplier * prestige_bonus

# Probabilidad extra (sumada, no multiplicada) de que una fruta sea "Gran Venta"/Jackpot.
func get_final_jackpot_bonus() -> float:
	var run_bonus: float = run_upgrade_levels["luck"] * 0.003
	var prestige_bonus: float = SaveManager.get_prestige_level("good_fortune") * 0.01
	return run_bonus + card_jackpot_bonus + prestige_bonus

func get_final_jackpot_multiplier() -> float:
	return 5.0 + card_jackpot_multiplier_bonus

func get_golden_fruit_chance() -> float:
	return GOLDEN_FRUIT_CHANCE + card_golden_fruit_chance

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
	var run_bonus: float = 1.0 + (run_upgrade_levels["launch_rate"] * RUN_LAUNCH_BONUS_PER_LEVEL)
	var prestige_bonus: float = 1.0 + (SaveManager.get_prestige_level("launch_speed") * PRESTIGE_LAUNCH_BONUS_PER_LEVEL)
	return BASE_LAUNCH_RATE * run_bonus * card_launch_rate_multiplier * prestige_bonus

# Probabilidad de que cada lanzamiento sea un obstáculo; crece con el pedido
# actual pero nunca supera MAX_OBSTACLE_CHANCE.
func get_obstacle_chance() -> float:
	var extra: float = float(maxi(0, GameManager.current_order - 1)) * OBSTACLE_CHANCE_PER_ORDER
	return minf(BASE_OBSTACLE_CHANCE + extra, MAX_OBSTACLE_CHANCE)

# Penalización de resistencia por golpear un obstáculo (fracción de la máxima).
func get_obstacle_resistance_penalty() -> float:
	return maxf(1.0, get_final_max_energy() * OBSTACLE_RESISTANCE_PENALTY_FRACTION)

# Precio final de las mejoras del mercado: sube geométricamente con cada nivel
# ya comprado (base_cost * cost_mult ^ nivel_actual).
func get_run_upgrade_cost(upgrade_id: String) -> int:
	if not run_upgrade_definitions.has(upgrade_id):
		return 999999
	var def: Dictionary = run_upgrade_definitions[upgrade_id]
	var level: int = run_upgrade_levels[upgrade_id]
	return int(round(def["base_cost"] * pow(def["cost_mult"], level) * card_upgrade_price_multiplier))

func get_order_target_multiplier() -> float:
	return card_order_target_multiplier

func can_buy_run_upgrade(upgrade_id: String, current_money: float) -> bool:
	return current_money >= get_run_upgrade_cost(upgrade_id)

func buy_run_upgrade(upgrade_id: String) -> void:
	if run_upgrade_levels.has(upgrade_id):
		run_upgrade_levels[upgrade_id] += 1
		emit_signal("stats_updated")

func apply_card_upgrade(card_id: String, effect_type: String, effect_value: Variant, card_title: String = "") -> void:
	active_cards.append({"id": card_id, "title": card_title})
	SaveManager.discover_card(card_id)
	if effect_type == "multi":
		for effect in effect_value:
			_apply_card_effect(str(effect["type"]), float(effect["value"]))
	else:
		_apply_card_effect(effect_type, float(effect_value))
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

# ----------------------------------------------------------------------------
# MEJORAS DE PRESTIGIO (permanentes, compradas con reputación/estrellas)
# ----------------------------------------------------------------------------
# A diferencia de las mejoras del mercado, estas NO se resetean nunca. Se
# guardan en SaveManager (prestige_levels) y su costo también sube con cada
# nivel (base_cost * mult ^ nivel_actual), igual que las mejoras del mercado.
var prestige_definitions: Dictionary = {
	"experience": {
		"name": "Maestría",
		"desc": "+20% Daño inicial por nivel",
		"base_cost": 10,
		"mult": 2.2,
		"icon": "⚔️"
	},
	"expert_hand": {
		"name": "Experiencia",
		"desc": "+20% Resistencia Máxima por nivel",
		"base_cost": 25,
		"mult": 2.2,
		"icon": "🧤"
	},
	"good_provider": {
		"name": "Buen Proveedor",
		"desc": "+20% Multiplicador de Ganancias por nivel",
		"base_cost": 50,
		"mult": 2.2,
		"icon": "📦"
	},
	"good_fortune": {
		"name": "Buena Fortuna",
		"desc": "+1% Probabilidad de Jackpot por nivel",
		"base_cost": 100,
		"mult": 2.2,
		"icon": "⭐"
	},
	"launch_speed": {
		"name": "Ritmo Veloz",
		"desc": "+25% Frecuencia de Lanzamiento por nivel",
		"base_cost": 60,
		"mult": 2.2,
		"icon": "🚀"
	},
}

func get_prestige_upgrade_cost(upgrade_id: String) -> int:
	if not prestige_definitions.has(upgrade_id):
		return 999999
	var def: Dictionary = prestige_definitions[upgrade_id]
	var current_lvl: int = SaveManager.get_prestige_level(upgrade_id)
	return int(round(def["base_cost"] * pow(def["mult"], current_lvl)))

func buy_prestige_upgrade(upgrade_id: String) -> bool:
	var cost: int = get_prestige_upgrade_cost(upgrade_id)
	if SaveManager.spend_prestige_points(cost):
		var new_lvl: int = SaveManager.get_prestige_level(upgrade_id) + 1
		SaveManager.set_prestige_level(upgrade_id, new_lvl)
		emit_signal("stats_updated")
		return true
	return false
