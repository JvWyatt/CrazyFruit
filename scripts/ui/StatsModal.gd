extends Control
# ============================================================================
# StatsModal: pantalla de "Stats" que muestra en detalle los valores finales
# calculados por StatsManager (daño, energía, crítico, etc). Solo lectura;
# útil para ver el efecto combinado de mejoras + comodines + prestigio.
# ============================================================================

signal modal_closed
signal open_cards_requested

@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var continue_button: Button = $Panel/VBox/ContinueButton
@onready var cards_button: Button = $Panel/VBox/CardsButton
@onready var stats_container: VBoxContainer = $Panel/VBox/ScrollContainer/StatsVBox

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	continue_button.pressed.connect(_on_close_pressed)
	cards_button.pressed.connect(_on_cards_pressed)
	StatsManager.stats_updated.connect(_refresh_ui)

func open_modal() -> void:
	visible = true
	UiTheme.pop_in($Panel)
	_refresh_ui()

func _refresh_ui() -> void:
	for child in stats_container.get_children():
		child.queue_free()

	var dmg: float = StatsManager.get_final_damage()
	var max_en: float = StatsManager.get_final_max_energy()
	var cost_en: float = StatsManager.get_final_energy_cost()
	var jackpot_bonus: float = StatsManager.get_final_jackpot_bonus() * 100.0
	var jackpot_multiplier: float = StatsManager.get_final_jackpot_multiplier()
	var golden_fruit_chance: float = StatsManager.get_golden_fruit_chance() * 100.0
	var crit_chance: float = StatsManager.get_final_critical_chance() * 100.0
	var crit_mult: float = StatsManager.get_final_critical_multiplier()
	var launch_rate: float = StatsManager.get_final_launch_rate()

	var base_dmg: float = float(StatsManager.get_equipped_knife_data().get("damage", 10.0))
	var dmg_bonus_pct: int = int(round((dmg / base_dmg - 1.0) * 100.0)) if base_dmg > 0.0 else 0
	var base_energy: float = 100.0
	var energy_bonus_pct: int = int(round((max_en / base_energy - 1.0) * 100.0))

	# Section 1: Combate y Corte
	_add_header("⚔️ CORTE")
	_add_stat_row("Daño del arma", str(int(round(dmg))), "Base: " + str(int(round(base_dmg))) + " | Bonus de mejoras: +" + str(dmg_bonus_pct) + "%", Color(1.0, 0.4, 0.4))
	_add_stat_row("Coste de Resistencia por Golpe", str(snappedf(cost_en, 0.1)) + " ⚡", "Depende del utensilio en uso", Color(0.9, 0.9, 0.9))
	_add_stat_row("Probabilidad de Crítico", str(int(round(crit_chance))) + "%", "Otorga daño multiplicado en cortes", Color(0.8, 0.5, 1.0))
	_add_stat_row("Multiplicador de Crítico", "x" + str(snappedf(crit_mult, 0.1)), "Daño FIJO aplicado al asestar un crítico (x2)", Color(0.8, 0.5, 1.0))

	# Section 2: Resistencia
	_add_header("🛡️ RESISTENCIA")
	_add_stat_row("Resistencia Máxima", str(int(round(max_en))), "Base: " + str(int(base_energy)) + " | Bonus de mejoras: +" + str(energy_bonus_pct) + "%", Color(0.3, 0.8, 1.0))

	# Section 3: Frutas
	_add_header("🍓 FRUTAS")
	_add_stat_row("Vida de las frutas", "x" + str(snappedf(StatsManager.card_fruit_hp_multiplier, 0.01)), "Multiplicador de vida de las frutas", Color(1.0, 0.5, 0.5))
	_add_stat_row("Frecuencia de lanzamiento", str(snappedf(launch_rate, 0.1)) + " frutas/s", "Frutas lanzadas por segundo según mejoras y comodines", Color(0.4, 0.9, 0.5))

	# Section 4: Economía
	_add_header("💰 ECONOMÍA")
	_add_stat_row("Recompensa mínima de frutas", "x" + str(snappedf(StatsManager.card_reward_min_multiplier, 0.01)), "Multiplicador de recompensa mínima", Color(1.0, 0.88, 0.3))
	_add_stat_row("Recompensa máxima de frutas", "x" + str(snappedf(StatsManager.card_reward_max_multiplier, 0.01)), "Multiplicador de recompensa máxima", Color(1.0, 0.88, 0.3))
	_add_stat_row("Multiplicador de ganancias", "x" + str(snappedf(StatsManager.get_final_money_multiplier(), 0.01)), "Base: x1.0 | Bonus de mejoras: +" + str(int(round((StatsManager.get_final_money_multiplier() / StatsManager.card_money_multiplier - 1.0) * 100.0))) + "%", Color(1.0, 0.88, 0.3))
	_add_stat_row("Precio de armas", "x" + str(snappedf(StatsManager.card_weapon_price_multiplier, 0.01)), "Multiplicador de precios", Color(0.8, 0.85, 1.0))
	_add_stat_row("Precio de frutas", "x" + str(snappedf(StatsManager.card_fruit_price_multiplier, 0.01)), "Multiplicador de precios", Color(0.8, 0.85, 1.0))
	_add_stat_row("Precio de mejoras", "x" + str(snappedf(StatsManager.card_upgrade_price_multiplier, 0.01)), "Multiplicador de precios", Color(0.8, 0.85, 1.0))

	# Section 5: Suerte
	_add_header("🍀 SUERTE")
	_add_stat_row("Probabilidad de Jackpot", "+" + str(int(round(jackpot_bonus))) + "% extra", "Multiplica la recompensa máxima", Color(1.0, 0.75, 0.2))
	_add_stat_row("Multiplicador de Jackpot", "x" + str(snappedf(jackpot_multiplier, 0.1)), "Recompensa de un Jackpot", Color(1.0, 0.75, 0.2))
	_add_stat_row("Probabilidad de Fruta Dorada", str(int(round(golden_fruit_chance))) + "%", "Probabilidad activa de fruta dorada", Color(1.0, 0.85, 0.2))

	_add_header("🃏 COMODINES ACTIVOS")
	if StatsManager.active_cards.is_empty():
		_add_stat_row("Comodines", "Ninguno", "Se obtienen al completar días", Color(0.6, 0.65, 0.75))
	else:
		for card in StatsManager.active_cards:
			_add_stat_row(str(card.get("title", "Comodín")), "ⓘ", "Consulta los comodines activos", Color(0.3, 0.95, 0.7))

func _add_header(title: String) -> void:
	var header_lbl := Label.new()
	header_lbl.text = title
	header_lbl.add_theme_font_size_override("font_size", 16)
	header_lbl.modulate = Color(1.0, 0.85, 0.3)
	stats_container.add_child(header_lbl)

func _add_stat_row(label_text: String, value_text: String, sub_desc: String, val_color: Color) -> void:
	var panel := PanelContainer.new()
	UiTheme.apply_card(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	var hbox := HBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.modulate = Color(0.9, 0.95, 1.0)

	var val_lbl := Label.new()
	val_lbl.text = value_text
	val_lbl.add_theme_font_size_override("font_size", 17)
	val_lbl.modulate = val_color

	hbox.add_child(name_lbl)
	hbox.add_child(val_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = sub_desc
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.modulate = Color(0.65, 0.72, 0.82)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	vbox.add_child(hbox)
	vbox.add_child(desc_lbl)

	panel.add_child(vbox)
	stats_container.add_child(panel)

func _on_close_pressed() -> void:
	SoundManager.play_click()
	visible = false
	emit_signal("modal_closed")

func _on_cards_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_cards_requested")
