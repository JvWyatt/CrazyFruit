class_name CardDatabase
extends RefCounted
# ============================================================================
# CardDatabase
# ----------------------------------------------------------------------------
# Catálogo de todos los "comodines" (cartas) que el jugador puede elegir al
# completar un pedido (ver CardSelectionModal.gd). Son bonos TEMPORALES que
# se pierden al quebrar el negocio (aplicados en StatsManager._apply_card_effect).
#
# Cada carta tiene una rareza (Común/Rara/Épica/Legendaria/Mítico) que suele
# indicar qué tan fuerte es su efecto, y un "effect_type" que dice QUÉ stat
# modifica (ver la lista de casos en StatsManager._apply_card_effect para el
# significado exacto de cada effect_type). Para cambiar el balance de una
# carta, solo edita el número (effect_value) de su línea _card(...).
# ============================================================================

static var ALL_CARDS: Array[Dictionary] = _build_cards()

static func _build_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var common := "Común"
	var rare := "Rara"
	var epic := "Épica"
	var legendary := "Legendaria"

	# Common pool: 20 cards
	cards.append(_card("Filo Ligero", "+3% daño", common, "damage", 0.03))
	cards.append(_card("Buen Aguante", "+3% resistencia máxima", common, "energy_max", 0.03))
	cards.append(_card("Cosecha Segura", "+3% recompensa mínima de frutas", common, "reward_min", 0.03))
	cards.append(_card("Fruta Valiosa", "+3% recompensa máxima de frutas", common, "reward_max", 0.03))
	cards.append(_card("Pequeña Fortuna", "+0.3% probabilidad de Jackpot", common, "jackpot", 0.003))
	cards.append(_card("Premio Mayor", "+0.1x multiplicador de Jackpot", common, "jackpot_multiplier", 0.1))
	cards.append(_card("Buen Negocio", "+3% multiplicador de ganancias", common, "money", 0.03))
	cards.append(_card("Punto Preciso", "+1% probabilidad de Crítico", common, "crit_chance", 0.01))
	cards.append(_card("Ritmo Constante", "+3% frecuencia de lanzamiento", common, "launch_rate", 0.03))
	cards.append(_card("Fruta Delicada", "-3% vida de las frutas", common, "fruit_hp", -0.03))
	cards.append(_card("Armas Baratas", "-3% precio de armas", common, "weapon_price", -0.03))
	cards.append(_card("Frutas Baratas", "-3% precio de frutas", common, "fruit_price", -0.03))
	cards.append(_card("Mejoras Baratas", "-3% precio de mejoras", common, "upgrade_price", -0.03))
	cards.append(_card("Buen Progreso", "-3% objetivo de dinero del día", common, "order_target", -0.03))
	cards.append(_multi_card("Filo Afortunado", "+2% daño y +0.2% Jackpot", common, [{"type": "damage", "value": 0.02}, {"type": "jackpot", "value": 0.002}]))
	cards.append(_multi_card("Cosecha Rentable", "+2% recompensa mínima y +2% máxima", common, [{"type": "reward_min", "value": 0.02}, {"type": "reward_max", "value": 0.02}]))
	cards.append(_multi_card("Golpe Valioso", "+2% Crítico y +2% multiplicador de dinero", common, [{"type": "crit_chance", "value": 0.02}, {"type": "money", "value": 0.02}]))
	cards.append(_multi_card("Corte Eficiente", "+2% daño y +2% resistencia máxima", common, [{"type": "damage", "value": 0.02}, {"type": "energy_max", "value": 0.02}]))
	cards.append(_multi_card("Lluvia Ligera", "+2% frecuencia de lanzamiento y +2% recompensa máxima", common, [{"type": "launch_rate", "value": 0.02}, {"type": "reward_max", "value": 0.02}]))
	cards.append(_multi_card("Cosecha Veloz", "+2% frecuencia de lanzamiento y +2% daño", common, [{"type": "launch_rate", "value": 0.02}, {"type": "damage", "value": 0.02}]))

	# Rare pool: 15 cards
	cards.append(_card("Filo Superior", "+7% daño", rare, "damage", 0.07))
	cards.append(_card("Reserva Extra", "+8% resistencia máxima", rare, "energy_max", 0.08))
	cards.append(_card("Cosecha Rica", "+8% recompensa mínima", rare, "reward_min", 0.08))
	cards.append(_card("Fruta Dorada", "+8% recompensa máxima", rare, "reward_max", 0.08))
	cards.append(_card("Fortuna Creciente", "+1% Jackpot", rare, "jackpot", 0.01))
	cards.append(_card("Jackpot Mejorado", "+0.3x multiplicador de Jackpot", rare, "jackpot_multiplier", 0.3))
	cards.append(_card("Negocio Próspero", "+7% multiplicador de ganancias", rare, "money", 0.07))
	cards.append(_card("Golpe Certero", "+4% Crítico", rare, "crit_chance", 0.04))
	cards.append(_card("Ritmo Fuerte", "+7% frecuencia de lanzamiento", rare, "launch_rate", 0.07))
	cards.append(_card("Fruta Frágil", "-7% vida de las frutas", rare, "fruit_hp", -0.07))
	cards.append(_card("Comerciante", "-7% precio de armas, frutas y mejoras", rare, "all_prices", -0.07))
	cards.append(_card("Día Favorable", "-7% objetivo de dinero del día", rare, "order_target", -0.07))
	cards.append(_multi_card("Racha de Cortes", "+4% Crítico y +4% daño", rare, [{"type": "crit_chance", "value": 0.04}, {"type": "damage", "value": 0.04}]))
	cards.append(_multi_card("Lluvia Rentable", "+4% frecuencia de lanzamiento y +4% recompensa mínima", rare, [{"type": "launch_rate", "value": 0.04}, {"type": "reward_min", "value": 0.04}]))
	cards.append(_multi_card("Negocio Veloz", "+4% frecuencia de lanzamiento y +4% ganancias", rare, [{"type": "launch_rate", "value": 0.04}, {"type": "money", "value": 0.04}]))

	# Epic pool: 10 cards
	cards.append(_card("Filo Devastador", "+15% daño", epic, "damage", 0.15))
	cards.append(_card("Reserva Titánica", "+20% resistencia máxima", epic, "energy_max", 0.20))
	cards.append(_multi_card("Cosecha Abundante", "+15% recompensa mínima y máxima", epic, [{"type": "reward_min", "value": 0.15}, {"type": "reward_max", "value": 0.15}]))
	cards.append(_multi_card("Fortuna Dorada", "+2% Jackpot y +0.5x multiplicador de Jackpot", epic, [{"type": "jackpot", "value": 0.02}, {"type": "jackpot_multiplier", "value": 0.5}]))
	cards.append(_multi_card("Golpe Mortal", "+7% Crítico y +15% daño", epic, [{"type": "crit_chance", "value": 0.07}, {"type": "damage", "value": 0.15}]))
	cards.append(_card("Mercado Dorado", "+15% multiplicador de ganancias", epic, "money", 0.15))
	cards.append(_card("Tormenta de Frutas", "+15% frecuencia de lanzamiento", epic, "launch_rate", 0.15))
	cards.append(_card("Fruta Frágil II", "-15% vida de las frutas", epic, "fruit_hp", -0.15))
	cards.append(_multi_card("Cortes en Cadena", "+8% Crítico y +10% frecuencia de lanzamiento", epic, [{"type": "crit_chance", "value": 0.08}, {"type": "launch_rate", "value": 0.10}]))
	cards.append(_multi_card("Viento a Favor", "+10% frecuencia de lanzamiento y +10% recompensa máxima", epic, [{"type": "launch_rate", "value": 0.10}, {"type": "reward_max", "value": 0.10}]))

	# Legendary pool: 5 cards
	cards.append(_card("Filo Supremo", "+30% daño", legendary, "damage", 0.30))
	cards.append(_multi_card("Resistencia Titánica", "+35% resistencia máxima y +15% frecuencia de lanzamiento", legendary, [{"type": "energy_max", "value": 0.35}, {"type": "launch_rate", "value": 0.15}]))
	cards.append(_multi_card("Fortuna Suprema", "+3% Jackpot y +1x multiplicador de Jackpot", legendary, [{"type": "jackpot", "value": 0.03}, {"type": "jackpot_multiplier", "value": 1.0}]))
	cards.append(_multi_card("Golpe Perfecto", "+10% Crítico y +30% daño", legendary, [{"type": "crit_chance", "value": 0.10}, {"type": "damage", "value": 0.30}]))
	cards.append(_multi_card("Cosecha Torrencial", "+30% frecuencia de lanzamiento, +20% recompensa y +20% ganancias", legendary, [{"type": "launch_rate", "value": 0.30}, {"type": "reward_min", "value": 0.20}, {"type": "reward_max", "value": 0.20}, {"type": "money", "value": 0.20}]))

	# Golden fruit pool: 5 cards, including the requested Mythic card.
	cards.append(_card("Brillo Dorado", "+0.0625% de Probabilidad de Fruta Dorada", common, "golden_fruit_chance", 0.000625))
	cards.append(_card("Toque Dorado", "+0.125% de Probabilidad de Fruta Dorada", rare, "golden_fruit_chance", 0.00125))
	cards.append(_card("Cosecha Dorada", "+0.25% de Probabilidad de Fruta Dorada", epic, "golden_fruit_chance", 0.0025))
	cards.append(_card("Leyenda Dorada", "+0.5% de Probabilidad de Fruta Dorada", legendary, "golden_fruit_chance", 0.005))
	cards.append(_card("Oro Puro", "+1% de Probabilidad de Fruta Dorada", "Mítico", "golden_fruit_chance", 0.01))
	return cards

static func _card(title: String, desc: String, rarity: String, effect_type: String, effect_value: float) -> Dictionary:
	return {"id": "card_" + title.to_lower().replace(" ", "_"), "title": title, "desc": desc, "icon": "🃏", "rarity": rarity, "color": _rarity_color(rarity), "effect_type": effect_type, "effect_value": effect_value}

# Igual que _card(), pero para una carta que aplica VARIOS efectos a la vez
# (por ejemplo +daño y +jackpot juntos en la misma carta).
static func _multi_card(title: String, desc: String, rarity: String, effects: Array) -> Dictionary:
	return {"id": "card_" + title.to_lower().replace(" ", "_"), "title": title, "desc": desc, "icon": "🃏", "rarity": rarity, "color": _rarity_color(rarity), "effect_type": "multi", "effects": effects}

static func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Común": return Color(0.3, 0.7, 1.0)
		"Rara": return Color(0.3, 0.9, 0.4)
		"Épica": return Color(0.8, 0.4, 1.0)
		"Legendaria": return Color(1.0, 0.75, 0.1)
		_: return Color(1.0, 0.4, 0.8)

static func get_random_cards(count: int = 3) -> Array[Dictionary]:
	var pool: Array[Dictionary] = ALL_CARDS.duplicate()
	pool.shuffle()
	var selected: Array[Dictionary] = []
	var limit: int = min(count, pool.size())
	for i in range(limit):
		selected.append(pool[i])
	return selected
