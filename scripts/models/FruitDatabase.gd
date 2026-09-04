class_name FruitDatabase
extends RefCounted
# ============================================================================
# FruitDatabase
# ----------------------------------------------------------------------------
# Tabla de balance de TODAS las frutas del juego. Edita los valores aquí para
# cambiar la dificultad/recompensa de cada fruta. Significado de cada campo:
#   - max_hp:         vida máxima (cuántos golpes aguanta según el daño del arma).
#                     Curva ×1.9: fruta 1 = 20 HP, fruta 20 ≈ 3.96M HP.
#   - min_reward/max_reward: rango de dinero que paga al cortarla (antes de
#                     multiplicadores de mejoras/comodines/prestigio).
#                     max_reward = 2^(orden-1): fresa = $1, cada rango duplica el
#                     máximo anterior (fruta 20 ≈ $524K). min_reward = max_reward × 0.1
#                     (fresa $0.10–$1.00).
#   - jackpot_chance: probabilidad base (0.0 a 1.0) de "Gran Venta"/Jackpot
#   - unlock_order:   orden de aparición histórico (no cambia el precio)
#   - base_color/inner_color/accent_color/radius/shape_type: solo apariencia
#
# Estas frutas se desbloquean con dinero de la partida en la pestaña
# "Frutería" del mercado (ver RunUpgradeModal.gd) y se olvidan al quebrar el
# negocio (ver GameManager.run_unlocked_fruits).
# ============================================================================

static var FRUITS: Dictionary = {
	"strawberry": {
		"id": "strawberry",
		"name": "Fresa",
		"emoji": "🍓",
		"max_hp": 20.0,
		"min_reward": 0.1,
		"max_reward": 1,
		"jackpot_chance": 0.0,
		"unlock_order": 1,
		"base_color": Color(0.95, 0.22, 0.32),
		"inner_color": Color(1.0, 0.45, 0.55),
		"accent_color": Color(0.2, 0.8, 0.3),
		"radius": 20.0,
		"shape_type": "strawberry"
	},
	"banana": {
		"id": "banana",
		"name": "Banana",
		"emoji": "🍌",
		"max_hp": 38.0,
		"min_reward": 0.2,
		"max_reward": 2,
		"jackpot_chance": 0.0,
		"unlock_order": 2,
		"base_color": Color(0.98, 0.84, 0.15),
		"inner_color": Color(1.0, 0.94, 0.5),
		"accent_color": Color(0.55, 0.4, 0.1),
		"radius": 20.0,
		"shape_type": "banana"
	},
	"peach": {
		"id": "peach",
		"name": "Melocotón",
		"emoji": "🍑",
		"max_hp": 72.0,
		"min_reward": 0.4,
		"max_reward": 4,
		"jackpot_chance": 0.0,
		"unlock_order": 3,
		"base_color": Color(0.98, 0.55, 0.4),
		"inner_color": Color(1.0, 0.8, 0.55),
		"accent_color": Color(0.25, 0.7, 0.25),
		"radius": 20.0,
		"shape_type": "peach"
	},
	"cherry": {
		"id": "cherry",
		"name": "Cereza",
		"emoji": "🍒",
		"max_hp": 137.0,
		"min_reward": 0.8,
		"max_reward": 8,
		"jackpot_chance": 0.0,
		"unlock_order": 4,
		"base_color": Color(0.8, 0.08, 0.18),
		"inner_color": Color(1.0, 0.35, 0.4),
		"accent_color": Color(0.2, 0.7, 0.25),
		"radius": 14.0,
		"shape_type": "cherry"
	},
	"orange": {
		"id": "orange",
		"name": "Naranja",
		"emoji": "🍊",
		"max_hp": 261.0,
		"min_reward": 1.6,
		"max_reward": 16,
		"jackpot_chance": 0.0,
		"unlock_order": 5,
		"base_color": Color(0.95, 0.45, 0.08),
		"inner_color": Color(1.0, 0.75, 0.25),
		"accent_color": Color(0.25, 0.7, 0.2),
		"radius": 22.0,
		"shape_type": "orange"
	},
	"apple": {
		"id": "apple",
		"name": "Manzana",
		"emoji": "🍎",
		"max_hp": 495.0,
		"min_reward": 3.2,
		"max_reward": 32,
		"jackpot_chance": 0.0,
		"unlock_order": 6,
		"base_color": Color(0.88, 0.12, 0.18),
		"inner_color": Color(1.0, 0.85, 0.8),
		"accent_color": Color(0.25, 0.75, 0.2),
		"radius": 22.0,
		"shape_type": "apple"
	},
	"pear": {
		"id": "pear",
		"name": "Pera",
		"emoji": "🍐",
		"max_hp": 941.0,
		"min_reward": 6.4,
		"max_reward": 64,
		"jackpot_chance": 0.0,
		"unlock_order": 7,
		"base_color": Color(0.65, 0.82, 0.18),
		"inner_color": Color(0.9, 0.95, 0.45),
		"accent_color": Color(0.2, 0.55, 0.15),
		"radius": 21.0,
		"shape_type": "pear"
	},
	"kiwi": {
		"id": "kiwi",
		"name": "Kiwi",
		"emoji": "🥝",
		"max_hp": 1788.0,
		"min_reward": 12.8,
		"max_reward": 128,
		"jackpot_chance": 0.0,
		"unlock_order": 8,
		"base_color": Color(0.45, 0.28, 0.12),
		"inner_color": Color(0.45, 0.75, 0.2),
		"accent_color": Color(0.25, 0.5, 0.1),
		"radius": 18.0,
		"shape_type": "kiwi"
	},
	"mango": {
		"id": "mango",
		"name": "Mango",
		"emoji": "🥭",
		"max_hp": 3397.0,
		"min_reward": 25.6,
		"max_reward": 256,
		"jackpot_chance": 0.0,
		"unlock_order": 9,
		"base_color": Color(0.95, 0.55, 0.08),
		"inner_color": Color(1.0, 0.8, 0.2),
		"accent_color": Color(0.25, 0.65, 0.15),
		"radius": 25.0,
		"shape_type": "mango"
	},
	"lemon": {
		"id": "lemon",
		"name": "Limón",
		"emoji": "🍋",
		"max_hp": 6454.0,
		"min_reward": 51.2,
		"max_reward": 512,
		"jackpot_chance": 0.0,
		"unlock_order": 10,
		"base_color": Color(0.95, 0.82, 0.08),
		"inner_color": Color(1.0, 0.95, 0.4),
		"accent_color": Color(0.35, 0.65, 0.15),
		"radius": 19.0,
		"shape_type": "lemon"
	},
	"watermelon": {
		"id": "watermelon",
		"name": "Sandía",
		"emoji": "🍉",
		"max_hp": 12262.0,
		"min_reward": 102.4,
		"max_reward": 1024,
		"jackpot_chance": 0.0,
		"unlock_order": 11,
		"base_color": Color(0.18, 0.68, 0.32),
		"inner_color": Color(0.92, 0.18, 0.28),
		"accent_color": Color(0.08, 0.35, 0.15),
		"radius": 38.0,
		"shape_type": "watermelon"
	},
	"melon": {
		"id": "melon",
		"name": "Melón",
		"emoji": "🍈",
		"max_hp": 23298.0,
		"min_reward": 204.8,
		"max_reward": 2048,
		"jackpot_chance": 0.0,
		"unlock_order": 12,
		"base_color": Color(0.65, 0.85, 0.32),
		"inner_color": Color(0.95, 0.75, 0.3),
		"accent_color": Color(0.25, 0.55, 0.15),
		"radius": 33.0,
		"shape_type": "melon"
	},
	"pineapple": {
		"id": "pineapple",
		"name": "Piña",
		"emoji": "🍍",
		"max_hp": 44266.0,
		"min_reward": 409.6,
		"max_reward": 4096,
		"jackpot_chance": 0.0,
		"unlock_order": 13,
		"base_color": Color(0.92, 0.62, 0.1),
		"inner_color": Color(1.0, 0.82, 0.3),
		"accent_color": Color(0.15, 0.65, 0.25),
		"radius": 29.0,
		"shape_type": "pineapple"
	},
	"papaya": {
		"id": "papaya",
		"name": "Papaya",
		"emoji": "🥭",
		"max_hp": 84106.0,
		"min_reward": 819.2,
		"max_reward": 8192,
		"jackpot_chance": 0.0,
		"unlock_order": 14,
		"base_color": Color(0.95, 0.45, 0.12),
		"inner_color": Color(1.0, 0.62, 0.25),
		"accent_color": Color(0.25, 0.65, 0.15),
		"radius": 26.0,
		"shape_type": "papaya"
	},
	"coconut": {
		"id": "coconut",
		"name": "Coco",
		"emoji": "🥥",
		"max_hp": 159801.0,
		"min_reward": 1638.4,
		"max_reward": 16384,
		"jackpot_chance": 0.0,
		"unlock_order": 15,
		"base_color": Color(0.35, 0.18, 0.08),
		"inner_color": Color(0.9, 0.85, 0.65),
		"accent_color": Color(0.25, 0.55, 0.2),
		"radius": 30.0,
		"shape_type": "coconut"
	},
	"avocado": {
		"id": "avocado",
		"name": "Aguacate",
		"emoji": "🥑",
		"max_hp": 303623.0,
		"min_reward": 3276.8,
		"max_reward": 32768,
		"jackpot_chance": 0.0,
		"unlock_order": 16,
		"base_color": Color(0.2, 0.5, 0.16),
		"inner_color": Color(0.65, 0.82, 0.28),
		"accent_color": Color(0.35, 0.2, 0.08),
		"radius": 21.0,
		"shape_type": "avocado"
	},
	"dragon_fruit": {
		"id": "dragon_fruit",
		"name": "Pitahaya",
		"emoji": "🍈",
		"max_hp": 576883.0,
		"min_reward": 6553.6,
		"max_reward": 65536,
		"jackpot_chance": 0.0,
		"unlock_order": 17,
		"base_color": Color(0.85, 0.18, 0.45),
		"inner_color": Color(0.95, 0.85, 0.9),
		"accent_color": Color(0.2, 0.65, 0.3),
		"radius": 25.0,
		"shape_type": "dragon_fruit"
	},
	"guava": {
		"id": "guava",
		"name": "Guayaba",
		"emoji": "🥝",
		"max_hp": 1096077.0,
		"min_reward": 13107.2,
		"max_reward": 131072,
		"jackpot_chance": 0.0,
		"unlock_order": 18,
		"base_color": Color(0.45, 0.75, 0.28),
		"inner_color": Color(0.95, 0.5, 0.55),
		"accent_color": Color(0.2, 0.55, 0.15),
		"radius": 19.0,
		"shape_type": "guava"
	},
	"quince": {
		"id": "quince",
		"name": "Membrillo",
		"emoji": "🍐",
		"max_hp": 2082547.0,
		"min_reward": 26214.4,
		"max_reward": 262144,
		"jackpot_chance": 0.0,
		"unlock_order": 19,
		"base_color": Color(0.8, 0.72, 0.16),
		"inner_color": Color(1.0, 0.88, 0.35),
		"accent_color": Color(0.25, 0.55, 0.15),
		"radius": 24.0,
		"shape_type": "quince"
	},
	"pumpkin": {
		"id": "pumpkin",
		"name": "Calabaza",
		"emoji": "🎃",
		"max_hp": 3956839.0,
		"min_reward": 52428.8,
		"max_reward": 524288,
		"jackpot_chance": 0.0,
		"unlock_order": 20,
		"base_color": Color(0.95, 0.35, 0.06),
		"inner_color": Color(1.0, 0.62, 0.15),
		"accent_color": Color(0.2, 0.5, 0.12),
		"radius": 39.0,
		"shape_type": "pumpkin"
	},
}

static func get_fruit_data(fruit_id: String) -> Dictionary:
	if FRUITS.has(fruit_id):
		return FRUITS[fruit_id]
	return FRUITS["strawberry"]

# Devuelve los ids de fruta ORDENADOS por unlock_order (la secuencia de
# desbloqueo de la Frutería). Se usa para bloquear en cadena: no se puede
# comprar una fruta sin haber comprado la anterior.
static func get_sorted_fruit_ids() -> Array[String]:
	var ids: Array[String] = []
	for fruit_id in FRUITS.keys():
		ids.append(str(fruit_id))
	ids.sort_custom(func(a: String, b: String) -> bool:
		return int(FRUITS[a]["unlock_order"]) < int(FRUITS[b]["unlock_order"])
	)
	return ids


# Crea una fruta "real" (FruitData) a partir de la tabla de arriba, aplicando
# los multiplicadores de comodines activos (vida, recompensas).
# El max_hp final se redondea siempre hacia abajo (floor) para que la vida
# mostrada/usada en el juego sea siempre un número entero.
static func create_fruit_resource(fruit_id: String) -> FruitData:
	var dict: Dictionary = get_fruit_data(fruit_id)
	var fd := FruitData.new()
	fd.id = dict["id"]
	fd.display_name = dict["name"]
	fd.icon_emoji = dict["emoji"]
	fd.max_hp = floor(dict["max_hp"] * StatsManager.get_fruit_max_hp_multiplier())
	fd.min_reward = dict["min_reward"] * StatsManager.get_fruit_min_reward_multiplier()
	fd.max_reward = dict["max_reward"] * StatsManager.get_fruit_max_reward_multiplier()
	fd.jackpot_chance = dict["jackpot_chance"]
	fd.unlock_order = dict["unlock_order"]
	fd.base_color = dict["base_color"]
	fd.inner_color = dict["inner_color"]
	# Frutas x2 de tamaño: el radio de la DB se duplica en runtime para que los
	# sprites, el hitbox y el modelo 3D se vean el doble de grandes (antes eran
	# demasiado pequeñas). Scales sprite, hitbox y modelo 3D a la vez.
	fd.radius = dict["radius"] * 2.0
	return fd
